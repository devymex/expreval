#ifndef __EXPREVAL_H
#define __EXPREVAL_H

#include <map>

extern "C" void initialize(const std::map<std::string, double> &vars);
extern "C" void set_variable_value(const char *pKey, double dValue);
extern "C" double evaluate(const char *pStr);

#endif // #ifndef __EXPREVAL_H

