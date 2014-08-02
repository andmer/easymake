# Getting Started with Easymake #


  
## Introduction ##

Easymake is a generic makefile for C/C++ on linux system. For simple C/C++ application, you don't even need to write any single line of makefile code to build it! Well, actually, you should write an include statement to include the easymake.mk rather than make a copy of it and name the file "Makefile". I hope that at least one line of makefile include statement won't bother you :-)

Features are described as follows:

* Automatic C/C++ sources (*.c, *.cpp) file detection.
* Auto dependency generation.
* Simple testing supported. (Allow multi definition of the main function).
* VPATH perfectly supported.

The following three examples will show you how to build you program with easy_make step by step.


  
## Getting Started ##

This demostration shows you how to use easy_make in a simple program. Suppose we want to write a simple program, that take to number input by user and then shows the sum. The source code of this examele in the directory `samples/basics`.

  
### Write C/C++ code ###

This program is so simple enough that I should skip the C++ code design issue and show our code directly, and after that we will focuse on our topic.

File: main.cpp

``` cplusplus
// File: main.cpp

#include <iostream>

#include "math/add.h"

using namespace std;

int main(){
        cout<<"please enter two integer:"<<endl;

        int a,b;
        cin>>a>>b;

        cout<<"add("<<a<<","<<b<<") returns "<<add(a,b)<<endl;
}
```

File: math/add.h

    #ifndef ADD_H
    #define ADD_H
    
    // File: math/add.h
    
    int add(int,int);
    
    #endif

File: math/add.cpp

    // File: math/add.cpp
    
    #include "math/add.h"
    
    int add(int a,int b){
            return a+b;
    }

  
### Build Our Program with Easymake ###

I keep this example simple so that we could use command-line to build it directly. If you are familliar with makefile syntax, you can also write a makefile to build it from scratch in seconds. Now you may wonder how we build the program with easymake? I will show all the three methods for you to make it clear and you could compare these methods directly.
  
#### Build with Command Line ###

    g++ -c -o main.o main.cpp
    g++ -c -o add.o math/add.cpp -I.
    g++ -o target main.o add.o


Or we could use a single command `g++ -o target main.cpp math/add.cpp -I.` to build the program.

Now type `ls`, and then `./target` you could see the result of our program:

    [root@VM_6_207_centos basics]# ls
    add.o  bin  main.cpp  main.o  makefile  math  target
    [root@VM_6_207_centos basics]# ./target
    please enter two integer:
    5
    3
    add(5,3) returns 8
  
#### Build with Makefile from Scratch ###

Create a new file name Makefile and write our code as below:

    target: main.o add.o
            g++ -o target main.o add.o
    
    main.o: main.cpp
            g++ -c -o main.o main.cpp -I.
    
    add.o: math/add.cpp
            g++ -c -o add.o math/add.cpp -I.

The result is pretty much the same:

    [root@VM_6_207_centos basics]# make
    g++ -c -o main.o main.cpp -I.
    g++ -c -o add.o math/add.cpp -I.
    g++ -o target main.o add.o
    [root@VM_6_207_centos basics]# ls
    add.o  main.cpp  main.o  makefile  math  target
    [root@VM_6_207_centos basics]# ./target
    please enter two integer:
    8
    9
    add(8,9) returns 17

The advantage of using makefile is, if you properly specify the dependencies, you don&rsquo;t have to compile every source file in your project every time. But maintaining the dependencies manually is very tedious and error-prone, as the project grows larger and larger, even if you program is a clean modulization design. For example, suppose we want to add a `multiply.cpp` and `multiply.h` for the app being able to show the multiplication of two numbers, then we have to modify our makefile build our program. Morever, if the header file `add.h` is modified, the `multiply.cpp` don&rsquo;t need to be re-compiled, thus we shoud add more code in the makefile the specify the dependencies between .cpp files and .h files. So now I guess you could see the motivation of writing a generic makefile automatically maintaining dependencies for us.
  
#### Build with Easymake ####

In this program, simply include the `easy_make.mk` file could build our target. Now edit our Makefile as below:

    include ../../easy_make.mk

Simply type `make` to build our program. And I&rsquo;m gonna show you more details so you could understand how our program is built.

    [root@VM_6_207_centos basics]# ls
    main.cpp  makefile  math
    [root@VM_6_207_centos basics]# make
    g++ -c -o bin/main.o main.cpp  -I.
    entry detected
    g++ -c -o bin/math/add.o math/add.cpp  -I.
    g++ -o bin/target bin/main.o bin/math/add.o
    BUILD_ROOT/TARGET: bin/target
    ENTRY: main.cpp
    [root@VM_6_207_centos basics]# ./bin/target
    please enter two integer:
    3
    5
    add(3,5) returns 8

Youe may notice the main differences from previous examples is the `entry detected`, `BUILD_ROOT/TARGET: bin/target` and `ENTRY: main.cpp` in the output. The `bin/target` is our program. As for the entry, I will explain it later.

Take the look at our directory structure:

    [root@VM_6_207_centos basics]# tree .
    .
    ├── bin
    │   ├── easy_make_current_entry_file
    │   ├── easy_make_detected_entries
    │   ├── easy_make_entries_tmp.d
    │   ├── main.d
    │   ├── main.o
    │   ├── math
    │   │   ├── add.d
    │   │   └── add.o
    │   └── target
    ├── main.cpp
    ├── makefile
    └── math
     ├── add.cpp
     └── add.h
    
    3 directories, 12 files

Easymake use a folder `bin` as the `BUILD_ROOT` for generating code so that our source folder won&rsquo;t be polluted. Those `*.d` and `easy_make_*` files are generated by easymake to maintain the dependencies. The `*.d` file is makefile syntax, take a look at `main.d` for example:

    [root@VM_6_207_centos basics]# cat bin/main.d
    bin/main.o: main.cpp math/add.h
    
    math/add.h:

These dependencies are auto generated by easy make, so every time the math/add.h is modified, It will caused the main.o to be re-generated. Actually you don&rsquo;t need to understand all these issues in order to use easy make, so we should just omit these extra-generated files and build our program with simply a `make` command. If you&rsquo;re intrested, take a look at the source code in `easy_make.mk`. I believe it&rsquo;s properly commented and easy enough for understanding.

  
### User Options ###

Suppose you want to compile the program with gcc compiler&rsquo;s `-O2` optimization and linker&rsquo;s `-static` options. Now you need to write a bit of codes the change the options. Here&rsquo;s our new makefile:


    COMPILE_FLAGS   += -O2
    LINK_FLAGS      += -static
    
    include ../../easy_make.mk

Now rebuild the program:

    [root@VM_6_207_centos basics]# make clean
    rm -f \$(find bin -name \*.o)
    rm -f \$(find bin -name \*.d)
    rm -f \$(find bin -name \*.a)
    rm -f \$(find bin -name \*.so)
    rm -f \$(find bin -name \*.out)
    rm -f bin/target
    [root@VM_6_207_centos basics]# make
    g++ -c -o bin/main.o main.cpp -O2  -I.
     entry detected
    g++ -c -o bin/math/add.o math/add.cpp -O2  -I.
    g++ -o bin/target bin/main.o bin/math/add.o  -static
    BUILD_ROOT/TARGET: bin/target
    ENTRY: main.cpp

There&rsquo;re more options available to make easymake flexible. Try `make help` command and you will see them. Look at the informatin in the **basic settings** and **user settings**. The other parts is not necessary here.

    [root@VM_6_207_centos basics]# make help
    ---------------------
    basic settings:
    SETTINGS_ROOT       : build_settings
    BUILD_ROOT          : bin
    TARGET              : target
    VPATH               :
    CPPEXT              : cpp
    CEXT                : c
    GCC                 : gcc
    GXX                 : g++
    LINKER              : g++
    ---------------------
    user settings files:
    build_settings/entry_list
    build_settings/compile_flags
    build_settings/compile_search_path
    build_settings/link_flags
    build_settings/link_search_path
    ---------------------
    user settings:
    ENTRY_LIST          :
    ENTRY               :
    COMPILE_FLAGS       : -O2
    COMPILE_SEARCH_PATH :  .
    LINK_FLAGS          : -static
    LINK_SEARCH_PATH    :
    CPPSOURCES          : main.cpp math/add.cpp
    CSOURCES            :
    ---------------------
    internal informations:
       ...
       ...
       ...


  
## The Entry for Tests ##

Now suppose we need to add a multiply function to the previous program. First we write a C++ function to do the multiplication, and then before we modify the main.cpp, we should test the multiplication function to make sure the new add module is OK. The following example shows you how to do this with easymake. You could find the source code in the folder `samples/entries`.

  
### Write Multiply Module ###

File `math/multiply.h`:

    #ifndef MULTIPLY_H
    #define MULTIPLY_H
    
    #include "stdint.h"
    
    int64_t multiply(int32_t,int32_t);
    
    #endif

File `math/multiply.cpp`:

    #include "math/multiply.h"
    
    int64_t multiply(int32_t a,int32_t b){
            return (int64_t)a*(int64_t)b;
    }

  
### Write Test Code ###

Type `mkdir test` and then `vim test/multiply.cpp` to write our test code. For simplicity, just print the result of 8 multiplied by 8 int the main function.

    #include "math/multiply.h"
    
    #include <iostream>
    
    using namespace std;
    
    int main(){
            cout<<"multiply(8,8)="<<multiply(8,8)<<endl;
    }

  
### Build Our Test ###

In this case, simply type `make`, and then `./bin/target` you will see the output of our test code.

    [root@VM_6_207_centos entries]# make
    g++ -c -o bin/main.o main.cpp -O2  -I.
        entry detected
    g++ -c -o bin/math/add.o math/add.cpp -O2  -I.
    g++ -c -o bin/math/multiply.o math/multiply.cpp -O2  -I.
    g++ -c -o bin/test/multiply.o test/multiply.cpp -O2  -I.
        entry detected
    g++ -o bin/target bin/math/add.o bin/math/multiply.o bin/test/multiply.o  -static
    BUILD_ROOT/TARGET: bin/target
    ENTRY: test/multiply.cpp
    [root@VM_6_207_centos entries]# ./bin/target
    multiply(8,8)=64
    [root@VM_6_207_centos entries]#

Notice that `main.cpp` and `test/multiply.cpp` are both properly compiled, but only `test/multiply.cpp` is linked into our target. The value of `ENTRY` has changed into `test/multiply.cpp`. With easymake, any source file with a `main` function will be automatically detected. Among the entries, only one of them is picked by easymake and linked into the target. Note that an `ENTRY` dosen&rsquo;t necessary need to have a `main` function and dosen&rsquo;t even need to exist as a file, in some occations, building an so for example, this entry is picked so that other entries won&rsquo;t be linked into the target.

Now you must be wondering why? How is easymake able to decide to pick `test/multiply.cpp` rather than `main.cpp`? Behind the magic is the timestamps of the entry files. If there&rsquo;s more than one entry and the user did&rsquo;t specify which one to pick, The entry file with the newest timestamp will be picked by easymake automatically. 

If you need to specify the `ENTRY` explicitly, pick main.cpp for example, use the command `make ENTRY=main.cpp`:

    [root@VM_6_207_centos entries]# make ENTRY=main.cpp
    g++ -o bin/target bin/main.o bin/math/add.o bin/math/multiply.o  -static
    BUILD_ROOT/TARGET: bin/target
    ENTRY: main.cpp

Now we&rsquo;ve test our multiply module, We can Modify the main.cpp and glue the module into our program. The following step is omit here for abbreviation. You could look into the `samples/entries` folder if need to.
