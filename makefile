all: expreval test

expreval: lex.yy.c y.tab.c
	g++ -std=c++11 -g -O0 -I/usr/include/python3.6m lex.yy.c y.tab.c -o libexpreval.so -lpython3.6m -fPIC -shared

lex.yy.c: expreval.l
	lex expreval.l

y.tab.c:
	yacc expreval.y -d

test: test.cpp
	g++ -std=c++11 -g -O0 test.cpp -o test -L. -lexpreval

clean:
	rm expreval.yy.c -f
	rm y.tab.c -f
	rm y.tab.h -f

.PHONY: clean
