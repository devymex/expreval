# Expreval: A "C-like" Syntax Expression Evaluator
# Yumeng Wang (devymex@gmail.com)


## CONFIGURATION
BUILD_TYPE=RELEASE
BUILD_STATIC_LIBRARY=ON
PYTHON_INCLUDE_DIRS=$(shell pkg-config --cflags python3)
PYTHON_LIBRARIES=$(shell pkg-config --libs python3)
PWD=$(shell pwd)

## OUTPUT FILE NAME
SHARED_LIBRARY_NAME=build/libexpreval.so
STATIC_LIBRARY_NAME=build/libexpreval.a

## BUILD OPTIONS
ifeq ($(BUILD_TYPE), DEBUG)
CXX=g++ -std=c++11 -g -O0 -D_DEBUG -pthread
else
CXX=g++ -std=c++11 -O3 -pthread
endif

## TARGETS
ifeq ($(BUILD_STATIC_LIBRARY), ON)
all: $(SHARED_LIBRARY_NAME) $(STATIC_LIBRARY_NAME) test

test: test.cpp $(STATIC_LIBRARY_NAME)
	$(CXX) $^ $(STATIC_LIBRARY_NAME) -o $@ $(PYTHON_INCLUDE_DIRS) $(PYTHON_LIBRARIES)
else
all: $(SHARED_LIBRARY_NAME) test

test: test.cpp $(SHARED_LIBRARY_NAME)
	$(CXX) $< -o $@ -L. -lexpreval
endif

$(SHARED_LIBRARY_NAME): build/lex.o build/y.o #build/expreval_py.o
	$(CXX) $^ -o $(SHARED_LIBRARY_NAME) -fPIC -shared $(PYTHON_LIBRARIES)

$(STATIC_LIBRARY_NAME): build/lex.o build/y.o
	ar rvs $(STATIC_LIBRARY_NAME) $^

#build/expreval_py.o: expreval_py.cpp expreval.h
#	$(CXX) -c $< -o $@ -fPIC -I. $(PYTHON_INCLUDE_DIRS)

build/lex.o: build/lex.yy.c build/y.tab.h
	$(CXX) -c $< -o $@ -fPIC -I$(PWD)

build/y.o: build/y.tab.c
	$(CXX) -c $< -o $@ -fPIC -I$(PWD) $(PYTHON_INCLUDE_DIRS)

build/y.tab.h: build/y.tab.c

build/y.tab.c: expreval.y build_dir
	yacc $< -d -b build/y

build/lex.yy.c: expreval.l build_dir
	lex -o $@ $<

.PHONY: clean

clean:
	rm -rf build
	rm -f test
	rm -f $(SHARED_LIBRARY_NAME)
	rm -f $(STATIC_LIBRARY_NAME)

build_dir:
	mkdir -p build