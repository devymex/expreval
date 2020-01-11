#ifndef __EXPREVAL_HPP
#define __EXPREVAL_HPP

extern "C" void initialize();

extern "C" void add_variable(const char *pKey, double dValue);

extern "C" bool is_variable_exists(const char *pKey);

extern "C" bool remove_variable(const char *pKey);

extern "C" bool set_variable_value(const char *pKey, double dValue);

extern "C" double evaluate(const char *pStr);

#endif // #ifndef __EXPREVAL_HPP
