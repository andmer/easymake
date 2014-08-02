# Easymake 使用说明



## 介绍 ##

Easymake 是一个在linux系统中 C/C++ 开发的通用 makefile。在一个简单的 C/C++ 程序中使用 easymake，你甚至可以不写一行 makefile 代码来生成目标文件。不过，还是建议你使用一条 `include` 指令将 `easymake.mk` 包含进来，而不是拷贝一份然后把文件改名为makefile :-)

Easymake 包含以下功能：

* 自动扫描 C/C++ 源文件
* 自动生成依赖关系
* 支持简单的单元测试，可以很方便地管理多个程序入口（main 函数）。
* 很好地支持 `VPATH` 变量。

我将在后面的例子中一步步地教你如何使用 easymake 来构建你的应用程序。



## 上手 Easymake ##

在这一节中将展示如何在一个简单的程序中使用 easymake。接下来让我们一个加法程序，用户输入两个数字，然后程序输出这两个数字相加的结果。这个程序的源代码可以在 `samples/basics` 目录中找到。

  
### C/C++ 代码 ###

这个程序很简单，所以这里路过程序设计环节。这里直接展示程序的 C/C++ 代码，然后再转入我们的正题。

File: main.cpp

``` cplusplus
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

``` cplusplus
#ifndef ADD_H
#define ADD_H

int add(int,int);

#endif
```

File: math/add.cpp

``` cplusplus
#include "math/add.h"

int add(int a,int b){
        return a+b;
}
```


### 使用 Easymake 来构建程序 ###

这个程序的代码很简单，所以我们可以直接使用命令行来构建程序。如果你对 makefile 的语法熟悉，你也可以很快地写出一个 makefile 来做完成这个事情。那么如何使用 easymake 来构建这个程序呢？接下来将使用刚才提到的三种方法来构建程序，希望你能清晰地了解和比较这三种方式。
#### 使用命令行构建 ###

``` shell
g++ -c -o main.o main.cpp
g++ -c -o add.o math/add.cpp -I.
g++ -o target main.o add.o
```

或者也可以只用一条命令 `g++ -o target main.cpp math/add.cpp -I.` 来构建程序。

然后输入 `ls` 和 `./target`，就可以观察到程序的执行结果了：

    [root@VM_6_207_centos basics]# ls
    add.o  bin  main.cpp  main.o  makefile  math  target
    [root@VM_6_207_centos basics]# ./target
    please enter two integer:
    5
    3
    add(5,3) returns 8
  
#### 自己写一个 makefile 构建程序 ####

创建一个新的 Makefile 文件，代码如下：

``` makefile
target: main.o add.o
        g++ -o target main.o add.o

main.o: main.cpp
        g++ -c -o main.o main.cpp -I.

add.o: math/add.cpp
        g++ -c -o add.o math/add.cpp -I.
```

结果基本是一样的：

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

使用 makefile 的好处就是，如果能很好地确定依赖关系，那么就不需要在每次构建时把所有的源文件都重新编译一次。但是随着项目的代码的增长，即使在一个良好的模块化设计中，手工维护依赖关系也是一件很繁琐而且很容易出错的工作。例如，假设我们需要增加一个 `multiply.cpp` 和 `multiply.h` 文件，让程序支持乘法计算的功能，那么我必须修改我们的 makefile 才能构建新的程序。另外，如果头文件 `add.h` 被修改了，`multiply.cpp` 就不需要重新编译，所以我们应该在 makefile 中增加 .cpp 文件和 .h 文件之间的依赖关系的代码。到这里，我想你也会觉得我们应该有一个通用的 makefile 来帮助我们自动维护依赖关系了吧。

#### 使用 easymake 构建程序 ####

在这个例子中，包含 `easymake.mk` 文件就足够了。把我们的 Makefile 修改成下面的代码：

``` makefile
include ../../easymake.mk
```

在命令行中输入 `make` 构建我们的程序。接下来我们给你展示一些细节来帮助你理解 makefile 是如何构建程序的。

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

你也许也已经注意到，和之前的方式相比，主要的不同就是输出中的 `entry detected`，`BUILD_ROOT/TARGET: bin/target` 和 `ENTRY: main.cpp`。`bin/target` 就是我们的程序。至于这里的entry，会在后面讲到。

现在可以看一下当前的目录结构：

    [root@VM_6_207_centos basics]# tree .
    .
    ├── bin
    │   ├── easymake_current_entry_file
    │   ├── easymake_detected_entries
    │   ├── easymake_entries_tmp.d
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

Easymake 使用 `bin` 目录作为 `BUILD_ROOT`，用来存放生成的文件，这样一来我们的源文件目录也不会被污染。这里面的 `*.d` 和 `easy_make_*` 文件都是由 easymake 额外生成用来维护依赖关系的。`*.d` 的文件其实也算是 makefile 的一部分，例如 main.d 文件的内容如下：

    [root@VM_6_207_centos basics]# cat bin/main.d
    bin/main.o: main.cpp math/add.h
    
    math/add.h:

这些依赖关系是 easymake 自动生成的，所以每当 `math/add.h` 被修改了，`main.o` 就会重新生成。事实上，你不需要关注这些细节来使用 easymake，所以我们就忽略这些额外生成的文件吧。如果你有兴趣，可以查看 `easymake.mk` 的源代码，我觉得代码的注释得已经足够帮助你理解了。


### 用户选项 ###

如果你想使用 gcc 编译器的 `-O2` 优化选项和链接器的 `-static` 选项来构建这个程序。那么你需要增加几行代码来修改编译和链接选项。下面是修改后的 makefile：

``` makefile
COMPILE_FLAGS   += -O2
LINK_FLAGS      += -static

include ../../easymake.mk
```

然后重新构建程序：

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

除些以外，还有更多可供设置的选项，使用 `make help` 命令你就可以看到它们。注意 **basic settings** 和 **user settings** 两部分的内容即可，其他部分可以忽略。

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



## 用来测试的程序入口 ##

现在我们需要给程序增加一个乘法运算功能，首先写一个 C++ 函数来做乘法运算，然后，在我们修改 `main.cpp` 的代码之前，我们应该测试一下这个这个 C++ 函数的功能，确保新增加的乘法模块的逻辑是正确的。下面的例子会告诉你如果使用 easymake 来完成这项工作，你可以在 `samples/entries` 文件夹中找到这个例子的代码。

### 编写乘法模块的代码 ###

File `math/multiply.h`:

``` cplusplus
#ifndef MULTIPLY_H
#define MULTIPLY_H

#include "stdint.h"

int64_t multiply(int32_t,int32_t);

#endif
```

File `math/multiply.cpp`:

``` cplusplus
#include "math/multiply.h"

int64_t multiply(int32_t a,int32_t b){
        return (int64_t)a*(int64_t)b;
}
```

  
### 编写测试代码 ###

在命令行中输入 `mkdir test` 和 `vim test/multiply.cpp` 然后编写我们的代码。为了简单起见，这里仅仅是在 `main` 函数中打印了 8 乘 8 的结果。

``` cplusplus
#include "math/multiply.h"

#include <iostream>

using namespace std;

int main(){
        cout<<"multiply(8,8)="<<multiply(8,8)<<endl;
}
```

  
### 构建测试程序 ###

现在直接输入命令 `make` 和 `./bin/target` 就可以看到测试程序的输出了。

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

注意到 `main.cpp` 和 `test/multiply.cpp` 都有被成功编译，但是只有 `test/multiply.cpp` 被链接到目标文件中，而且输出中 `ENTRY` 对应的值也变成了 `test/multiply.cpp`。在 easymake，全体一个包含 `main` 函数定义的源文件都会被自动检测到，并且被当作程序入口文件（`ENTRY`）。在众多入口文件当中，只有一个会被选中，其他文件不会被链接到目标文件中。另外注意这里的 `ENTRY` 所表示的文件名对应的文件也可以不存在，在某些场景中，例如生成动态库 so 文件，就需要选择这个 `ENTRY` 来阻止其他入口文件被链接到目标文件中。

现在你肯定是在纳闷，easymake 是如何知道要选择 `test/multiply.cpp` 而不是 `main.cpp` 的？是不是很神奇？其实这里使用的是入口文件的最后修改时间。如果有多个入口文件，而且用户没有显式地声明使用哪个入口，那么 easymake 就会自动选择最新的那个计算器文件。

如果你需要显式地声明 `ENTRY`，以选择 `main.cpp` 为例，可以输入命令 `make ENTRY=main.cpp`：

    [root@VM_6_207_centos entries]# make ENTRY=main.cpp
    g++ -o bin/target bin/main.o bin/math/add.o bin/math/multiply.o  -static
    BUILD_ROOT/TARGET: bin/target
    ENTRY: main.cpp

到这里已经完成了乘法模块的测试，接下来可以修改 `main.cpp` 的代码来整合我们的新模块了。为了简洁，接下来的步骤就不在这里赘述了，如果有需要，可以查看 `samples/entries` 目录中的代码。

