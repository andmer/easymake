make ENTRY=so TARGET=libmymath.so

g++ test/multiply.cpp -I. -Lbin/ -lmymath -o bin/target

export LD_LIBRARY_PATH=bin/

bin/target
