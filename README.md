# 类 C 语法公式计算器

## 使用说明

1. clone 该项目：`clone https://gitlab.deepglint.com/yumengwang/expreval.git`；
2. 生成项目：`make`；
3. 执行命令 `./test` 测试 C 接口，`python test.py` 测试 Python 接口；
4. 阅读 test.cpp 了解 C 接口调用方法，阅读 test.py 了解 Python 接口调用方法。

## 可接受操作符（优先级由高到低）：

* 函数（min，max）
* 括号（()）
* 取负（-）
* 乘除（*，/）
* 加减（+，-）
* 比较（<，<=，>=，>）
* 相等（==，!=）
* 逻辑（||，&&）
* 条件（?:）

## 变量

可自定义变量名，但必须以下划线（'_'）作为起始字符。

## Q&A

* 生成失败：编辑 makefile 文件，修改 python 头文件所在路径和 python 库的版本后缀；
* C 接口测试程序不能运行：将工程目录加入环境变量 LD_LIBRARY_PATH ；
* 计算结果不正确：编辑 expreval.y 文件，取消所有LOG前的注释，再次生成并运行测试程序，可通过 LOG 信息定位问题。
