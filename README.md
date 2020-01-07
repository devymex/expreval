# Expreval: A "C-like" Syntax Expression Evaluator

类 C 语法表达式计算器，基于Lex/Yacc实现的递归下降文法分析引擎。数值计算均以 double 类型执行。

## 使用说明

1. 本项目当前仅在 Ubuntu 18.04 环境下进行开发和测试；
2. 若系统尚未安装 Flex 和 Bison，应先执行命令：`sudo apt-get install bison flex` 进行安装；
3. clone 或下载本项目到本地目录；
4. 在项目目录中执行命令 `make` 编译和生成项目；
5. 执行命令 `LD_LIBRARY_PATH=$(pwd):$LD_LIBRARY_PATH ./test` 测试 C 接口，阅读 test.cpp 了解 C 接口调用方法；
6. 执行命令 `python test.py` 测试 Python 接口，阅读 test.py 了解 Python 接口调用方法。

## 支持操作符（优先级由高到低）

* 一元函数、二元函数、括号（()）
* 否定（!）、一元正负（+，-）
* 乘除（*，/）
* 加减（+，-）
* 比较（<，<=，>=，>）
* 相等（==，!=）
* 逻辑与（&&）
* 逻辑或（||）
* 条件（?:）

## 可使用的预置函数

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

## 预置的常量

* e：2.71828182845904523536
* pi：3.14159265358979323846

## 变量

可自定义变量名，要求符合 C 语言的命名要求，且不能与任何预设函数名和常量名冲突。

## Q&A

* 生成DEBUG版本：编辑 makefile 文件，将 BUILD_TYPE 变量置为 DEBUG；
* 生成失败：编辑 makefile 文件，修改 PYTHON_FLAGS 变量以适配当前系统环境；
* C 接口测试程序不能运行：将工程目录加入环境变量 LD_LIBRARY_PATH ；
* 计算结果不正确：编辑测试例程，填入有问题的表达式和变量，然后生成DEBUG版本的程序库，再次运行测试程序后可通过 LOG 信息定位问题。
