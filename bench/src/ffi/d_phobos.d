module d_phobos;

import core.stdc.stdlib : malloc, free;

import std.algorithm.searching;
import std.algorithm.iteration;
import std.meta;
import std.range;
import std.regex;
import std.stdio;
import std.string;
import std.typecons;

enum easy0() = "ABCDEFGHIJKLMNOPQRSTUVWXYZ$";
enum easy1() = r"A[AB]B[BC]C[CD]D[DE]E[EF]F[FG]G[GH]H[HI]I[IJ]J$";
enum medium() = r"[XYZ]ABCDEFGHIJKLMNOPQRSTUVWXYZ$";
enum hard() = r"[ -~]*ABCDEFGHIJKLMNOPQRSTUVWXYZ$";
enum reallyhard() = r"[ -~]*ABCDEFGHIJKLMNOPQRSTUVWXYZ.*";
enum reallyhard2() = r"\w+\s+Holmes";
enum no_exponential = "\"a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"";
enum holmes_cochar_watson = q"<r"Holmes.{0,25}Watson|Watson.{0,25}Holmes">";
enum holmes_coword_watson = q"<r"Holmes(?:\s*.+\s*){0,10}Watson|Watson(?:\s*.+\s*){0,10}Holmes">";
enum quotes =  q"<`["'][^"']{0,30}[?!.]["']"`>";
enum ing_suffix_limited_space = q"<r"\s[a-zA-Z]{0,12}ing\s">";

string[] regexFromRustMacro(string file, string macroName)() {
    typeof(return) regexii;

    auto text = import(file);

    const start = macroName ~ "!(";

    ptrdiff_t startIndex;
    do {
        startIndex = text.indexOf(start);
        if (startIndex <= 0) {
            break;
        }
        text = text[startIndex + start.length .. $];
        ptrdiff_t commaIndex = text.indexOf(',');
        auto testName = text[0..commaIndex].strip();
        // special cases due to: a) This parser being super dumb; b) the test not using string literals
        if (file == "misc.rs" && testName == "no_exponential") {
            //regexii ~= no_exponential;
        } else if (file == "sherlock.rs" && testName == "holmes_cochar_watson") {
            regexii ~= holmes_cochar_watson;
        } else if (file == "sherlock.rs" && testName == "holmes_coword_watson") {
            regexii ~= holmes_coword_watson;
        } else if (file == "sherlock.rs" && testName == "quotes") {
            regexii ~= quotes;
        } else if (file == "sherlock.rs" && testName == "ing_suffix_limited_space") {
            regexii ~= ing_suffix_limited_space;
        } else {
            text = text[commaIndex+1 .. $];
            regexii ~= text[0..text.indexOf(',')];
        }
    } while(/*regexii.length < 1 &&*/ startIndex >= 0);


    return regexii;
}

auto rustRegexToD(string regex) {
    auto flags = "g";
    if (regex.startsWith("(?i)")) {
        flags = "gi";
        regex = regex[4..$];
    } else if (regex.startsWith("(?m)")) {
        flags = "gm";
        regex = regex[4..$];
    }
    return tuple(regex, flags);

}

template ctRegexFromMatches(string[] regexii) {
    static if (regexii.length == 0) {
        enum ctRegexFromMatches = [];
    } else {
        //pragma(msg, regexii[0]);
        enum ctRegexFromMatches = ctRegex!(rustRegexToD(mixin(regexii[0])).expand) ~
                                         ctRegexFromMatches!(regexii[1..$]);
    }
}

template ctPatternFromMatches(string[] regexii) {
    static if (regexii.length == 0) {
        enum ctPatternFromMatches = [];
    } else {
        //pragma(msg, regexii[0]);
        enum ctPatternFromMatches = [mixin(regexii[0])] ~
                                         ctPatternFromMatches!(regexii[1..$]);
    }
}


Regex!char[string] regexDict(string[] regexiiStr, Regex!(char)[] regexii) {
    typeof(return) dict;
    foreach (i, r; regexiiStr) {
        dict[r] = regexii[i];
    }
    return dict;
}

//pragma(msg, regexFromRustMacro!("misc.rs", "bench_match")());
immutable miscMatches = regexFromRustMacro!("misc.rs", "bench_match")();
immutable miscPatterns = ctPatternFromMatches!(miscMatches);
immutable miscRegex = ctRegexFromMatches!(miscMatches);

immutable miscNotMatches = regexFromRustMacro!("misc.rs", "bench_not_match")();
immutable miscNotPatterns = ctPatternFromMatches!(miscNotMatches);
immutable miscNotRegex = ctRegexFromMatches!(miscNotMatches);

//pragma(msg, regexFromRustMacro!("sherlock.rs", "sherlock")());
immutable sherlockMatches = regexFromRustMacro!("sherlock.rs", "sherlock")();
immutable sherlockPatterns = ctPatternFromMatches!(sherlockMatches);
immutable sherlockRegex = ctRegexFromMatches!(sherlockMatches);

//pragma(msg, regexFromRustMacro!("regexdna.rs", "dna")());
immutable regexdnaMatches = regexFromRustMacro!("regexdna.rs", "dna")();
immutable regexdnaPatterns = ctPatternFromMatches!(regexdnaMatches);
immutable regexdnaRegex = ctRegexFromMatches!(regexdnaMatches);

immutable patterns = miscPatterns ~ miscNotPatterns ~ sherlockPatterns ~ regexdnaPatterns;
immutable regexii = miscRegex ~ miscNotRegex ~ sherlockRegex ~ regexdnaRegex;

extern(C):

void* d_phobos_regex_new(string s, bool compileTime) {
    auto r = cast(Regex!char*)malloc(Regex!char.sizeof);
    if (compileTime) {
        bool foundMatch = false;
        foreach (i, pattern; patterns) {
            if (pattern == s) {
                *r = cast()regexii[i];
                foundMatch = true;
                break;
            }
        }
        if (!foundMatch) {
            stderr.writefln("probably going to crash");
            stderr.writefln("no ct regex found for: %s", s);
            stderr.writefln("available: %s", patterns);
            free(r);
            return null;
        }
    } else {
        *r = regex(rustRegexToD(s).expand);
    }
    return r;
}

void d_phobos_regex_free(void* r) {
    free(r);
}

bool d_phobos_regex_is_match(void* r, string s) {
    auto regex = *cast(Regex!char*)r;
    return !matchFirst(s, regex).empty;
}

bool d_phobos_regex_find_at(void* r, string s, size_t start, out size_t match_start, out size_t match_end) {
    auto regex = *cast(Regex!char*)r;
    auto match = matchFirst(s[start..$], regex);

    if (match.empty) {
        return false;
    }

    match_start = match.pre().ptr - s.ptr;
    match_end = match.post().ptr - s.ptr;
    return true;
}

