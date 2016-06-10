
make bin/libmylib.so

g++ test/multiply.cpp -I. -L./bin/ -lmylib -o bin/target

LD_LIBRARY_PATH=./bin/ ./bin/target
