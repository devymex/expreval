# Expreval: A "C-like" Syntax Expression Evaluator
# Yumeng Wang (devymex@gmail.com)

PYTHON_FLAGS=`pkg-config --cflags --libs python3`

BUILD_TYPE=RELEASE

ifeq ($(BUILD_TYPE), DEBUG)
	CXX=g++ -std=c++11 -g -O0
else
	CXX=g++ -std=c++11 -O3
endif

all: expreval test

expreval: lex.yy.c y.tab.c
	$(CXX) $^ -o lib$@.so -fPIC -shared $(PYTHON_FLAGS)

lex.yy.c: expreval.l
	lex $<

y.tab.c: expreval.y
	yacc $< -d

test: test.cpp
	$(CXX) $< -o $@ -L. -lexpreval

clean:
	rm expreval.yy.c -f
	rm y.tab.c -f
	rm y.tab.h -f

.PHONY: clean
