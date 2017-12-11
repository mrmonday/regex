dmd -w -c -O -release -inline d_phobos.d -J..
ar cr libdphobos-dmd.a d_phobos.o
ldc -w -c -O3 -release -mcpu=native d_phobos.d -of=d_phobos_ldc.o -J..
ar cr libdphobos-ldc.a d_phobos_ldc.o
