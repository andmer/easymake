set -x
make bin/libmylib.a
g++ -o bin/target test/multiply.cpp -I. -Lbin -lmylib 
