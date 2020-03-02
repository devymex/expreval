#ifndef __EXPREVAL_HPP
#define __EXPREVAL_HPP

using EXPREVAL_HANDLE = void*;

extern "C" EXPREVAL_HANDLE initialize();

extern "C" void unintialize(EXPREVAL_HANDLE pExprHdl);

extern "C" int add_variable(EXPREVAL_HANDLE pExprHdl,
		const char *pKey, double dValue);

extern "C" int remove_variable(EXPREVAL_HANDLE pExprHdl,
		const char *pKey);

extern "C" int set_variable_value(EXPREVAL_HANDLE pExprHdl,
		const char *pKey, double dValue);

extern "C" int get_variable_value(EXPREVAL_HANDLE pExprHdl,
		const char *pKey, double *pValue);

extern "C" double evaluate(EXPREVAL_HANDLE pExprHdl,
		const char *pStr);

extern "C" double evaluate_with_length(EXPREVAL_HANDLE pExprHdl,
		const char *pStr, int nLen);

extern "C" const char* format_error_message(int nErrCode);

#endif // #ifndef __EXPREVAL_HPP
