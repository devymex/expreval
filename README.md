# Expreval: A "C-like" Syntax Expression Evaluator

类 C 语法表达式计算器，基于 Lex/Yacc 实现的递归下降文法分析引擎。
数值计算均以 double 类型执行。

## 使用说明

本项目当前仅支持在 Ubuntu 18.04 环境下进行开发和测试，执行下面的命令安装依赖项：

`sudo apt-get install bison flex libpython3-dev`

### 生成项目

生成步骤：
1. clone 或下载本项目到本地目录；
2. 在项目目录中执行命令 `make` 编译和生成项目；
3. 执行命令 `make clean` 可删除所有生成项。

`makefile` 文件中的配置项包括：
* BUILD_TYPE：可指定 DEBUG 或 RELEASE，指定 DEBUG 时会有大量调试信息输出，指定 RELEASE 时会生成性能优化版本。
* BUILD_STATIC_LIBRARY：可指定 ON 或 OFF，指定为 ON 时，会额外生成静态链接库。此处需要注意的时，您的应用程序若要链接到静态库，也必须使用 PYTHON_LIBRARIES 所代表的选项。
* PYTHON_INCLUDE_DIRS：指定 `Python.h` 文件所在的路径作为编译器选项，因此路径前必须有 `-I` 前缀。通常情况下 `pkg-config --cflags python3` 命令可以自动获取这一选项。若这一命令选项失败，可以自行指定正确的路径。
* PYTHON_LIBRARIES：链接 Python3 的共享库作为链接器选项，因此必须有 `-l` 前缀。通常情况下 `pkg-config --libs python3` 命令可以自动获取这一选项。若这一命令选项失败，还可以使用如下命令获取：-l`python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"`

### 运行测试程序

执行命令 `env LD_LIBRARY_PATH=$(pwd):$LD_LIBRARY_PATH ./test` 测试 C 接口，阅读 test.cpp 了解 C 接口调用方法。

执行命令 `python test.py` 测试 Python 接口，阅读 test.py 了解 Python 接口调用方法。

## 参考

### 接口
头文件 `expreval.hpp` 中定义了全部的 C/C++ 接口函数。

void initialize();
程序初始化，通常只需调用一次。每次调用后，所有用户设定的变量都将被清除。

void add_variable(const char *pKey, double dValue);
添加一个用户变量。

bool is_variable_exists(const char *pKey);
判断 `pKey` 指定的用户变量是否存在。若存在，返回 true，否则返回 false。

bool remove_variable(const char *pKey);
删除 `pKey` 指定的用户变量。若删除成功，返回 true，若不存在该变量，返回 false。

void set_variable_value(const char *pKey, double dValue);
更改 `pKey` 指定的参数名的值为 `dValue` ，若设置成功，返回 true，若不存在该变量，返回 false。

double evaluate(const char *pStr);
计算 `pStr` 指定的表达式的值，并返回结果。若表达式字符串末尾以字符 '\n' 结束，计算性能会有 3% 左右的提升。

### 支持的操作符（按优先级由高到低排列）

* 一元函数、二元函数、括号（()）
* 否定（!）、一元正负（+，-）
* 乘除（*，/）
* 加减（+，-）
* 比较（<，<=，>=，>）
* 相等（==，!=）
* 逻辑与（&&）
* 逻辑或（||）
* 条件（?:）

### 可使用的预置函数

* min(v1, v2)
* max(v1, v2)
* atan2(y, x)
* pow(b, e)
* log(v)
* log10(v)
* exp(v)
* abs(v)
* ceil(v)
* floor(v)
* cos(v)
* cosh(v)
* acos(v)
* sin(v)
* sinh(v)
* asin(v)
* tan(v)
* tanh(v)
* atan(v)
* sqrt(v)
以上函数的行为均与 C++ STL 中的同名函数完全一致。

### 预置的常量

* e：2.71828182845904523536
* pi：3.14159265358979323846

### 变量

可自定义变量名，要求符合 C 语言的命名要求，且不能与任何预设函数名和常量名冲突。

## Q&A

* 生成DEBUG版本：编辑 makefile 文件，将 BUILD_TYPE 变量置为 DEBUG；
* 生成失败：编辑 makefile 文件，修改 PYTHON_FLAGS 变量以适配当前系统环境；
* C 接口测试程序不能运行：将工程目录加入环境变量 LD_LIBRARY_PATH ；
* 计算结果不正确：编辑测试例程，填入有问题的表达式和变量，然后生成DEBUG版本的程序库，再次运行测试程序后可通过 LOG 信息定位问题。
