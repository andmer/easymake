make ENTRY=ar TARGET=libmylib.a
g++ -o bin/target test/multiply.cpp -I. -Lbin -lmylib 
