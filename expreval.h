#ifndef __EXPREVAL_HPP
#define __EXPREVAL_HPP

extern "C" void initialize();

extern "C" int add_variable(const char *pKey, double dValue);

extern "C" int remove_variable(const char *pKey);

extern "C" int set_variable_value(const char *pKey, double dValue);

extern "C" int get_variable_value(const char *pKey, double *pValue);

extern "C" double evaluate(const char *pStr);

#endif // #ifndef __EXPREVAL_HPP
