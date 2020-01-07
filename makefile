# Expreval: A "C-like" Syntax Expression Evaluator
# Yumeng Wang (devymex@gmail.com)

PYTHON_FLAGS=`pkg-config --cflags --libs python3`

BUILD_TYPE=RELEASE

LIB_NAME=libexpreval.so

ifeq ($(BUILD_TYPE), DEBUG)
	CXX=g++ -std=c++11 -g -O0 -D_DEBUG
else
	CXX=g++ -std=c++11 -O3
endif

all: $(LIB_NAME) test

$(LIB_NAME): lex.yy.c y.tab.c
	$(CXX) $^ -o $(LIB_NAME) -fPIC -shared $(PYTHON_FLAGS)

lex.yy.c: expreval.l
	lex $<

y.tab.c: expreval.y
	yacc $< -d

test: test.cpp
	$(CXX) $< -o $@ -L. -lexpreval

clean:
	rm -f lex.yy.c
	rm -f y.tab.c
	rm -f y.tab.h
	rm -f test
	rm -r $(LIB_NAME)

.PHONY: clean
