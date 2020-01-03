# Expreval: A "C-like" Syntax Expression Evaluator
类 C 语法公式计算器

## 使用说明

1. 若系统尚未安装 flex 和 bison，先执行命令：`sudo apt-get install bison flex` 进行安装；
2. clone 或下载本项目到本地目录；
3. 编译和生成项目：`make`；
4. 执行命令 `./test` 测试 C 接口，`python test.py` 测试 Python 接口；
5. 阅读 test.cpp 了解 C 接口调用方法，阅读 test.py 了解 Python 接口调用方法。

## 支持操作符（优先级由高到低）：

* 一元函数
* 二元函数
* 括号（()）
* 取负（-）
* 乘除（*，/）
* 加减（+，-）
* 比较（<，<=，>=，>）
* 相等（==，!=）
* 逻辑（||，&&）
* 条件（?:）

## 预设的函数

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

## 预设的常量

* e：2.71828182845904523536
* pi：3.14159265358979323846

## 变量

可自定义变量名，要求符合 C 语言的命名要求，且不能与任何预设函数名和常量名冲突。

## Q&A

* 生成DEBUG版本：编辑 makefile 文件，将 BUILD_TYPE 变量置为 DEBUG；
* 生成失败：编辑 makefile 文件，修改 PYTHON_FLAGS 变量以适配当前系统环境；
* C 接口测试程序不能运行：将工程目录加入环境变量 LD_LIBRARY_PATH ；
* 计算结果不正确：编辑 expreval.y 文件，取消所有LOG前的注释，再次生成并运行测试程序，可通过 LOG 信息定位问题。
