%{
// Expreval: A "C-like" Syntax Expression Evaluator
// Yumeng Wang (devymex@gmail.com)


#include <cmath>
#include <functional>
#include <Python.h>

#include "value.hpp"
#include "logging.hpp"

#define ADD_UNARY_FUNCTION(func_name) \
	namedTokens[#func_name] = MakeValue(VT_UFUNC, ufuncList.size()); \
	ufuncList.push_back([](double v) { return std::func_name(v); });

#define ADD_BINARY_FUNCTION(func_name) \
	namedTokens[#func_name] = MakeValue(VT_BFUNC, bfuncList.size()); \
	bfuncList.push_back([](double a, double b) { return std::func_name(a, b); });

typedef struct yy_buffer_state *YY_BUFFER_STATE;

extern int yylex();
extern int yyparse();
extern YY_BUFFER_STATE yy_scan_string(const char *str);
extern YY_BUFFER_STATE yy_scan_bytes (const char *bytes, int len);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);

int yyerror(char const *str) {
	extern char *yytext;
	LOG(FATAL) << "parser error near " << yytext << ": " << str << std::endl;
	return 0;
}

std::vector<double> varList;
std::vector<std::function<double(double, double)>> bfuncList;
std::vector<std::function<double(double)>> ufuncList;

std::unordered_map<std::string, VALUE> namedTokens;

double dResult;

%}

%union {
	VALUE val;
}

%token <val> '+' '-' '*' '/' '?' ':'
%token <val> OP_LT OP_LE OP_GE OP_GT OP_EQ OP_NE CR
%token <val> CONSTANT VARIABLE BFUNC UFUNC
%type <val> EXPR CONDITIONAL ADDITIVE MULTIPLICATIVE PRIMARY
%type <val> LOGICAL_OR LOGICAL_AND EQUALITY RELATIONAL NEGATION

%right '?' ':'
%left OP_OR
%left OP_AND
%left OP_EQ OP_NE
%left OP_LT OP_LE OP_GE OP_GT
%left '+' '-'
%left '*' '/'
%right NEG '!'
%left '(' ')'

%%

EXPR
: CONDITIONAL CR {
		$$ = $1;
		dResult = $$.fval;
#ifdef _DEBUG
		LOG(INFO) << "CONDITIONAL=" << $$.fval;
#endif
		YYACCEPT;
	}
;

CONDITIONAL
: ADDITIVE {
		$$ = $1;
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << "ADDITIVE=" << $$.fval;
#endif
	}
| LOGICAL_OR '?' CONDITIONAL ':' CONDITIONAL {
		if ($3.type == VT_INT && $5.type == VT_INT) {
			$$.ival = $1.ival ? $3.ival : $5.ival;
			$$.type = VT_INT;
#ifdef _DEBUG
			LOG(INFO) << $1.ival << "?" << $3.ival << ":" << $5.ival << " -> " << $$.ival;
#endif
		} else if ($3.type == VT_FLOAT && $5.type == VT_FLOAT) {
			$$.fval = $1.ival ? $3.fval : $5.fval;
			$$.type = VT_FLOAT;
#ifdef _DEBUG
			LOG(INFO) << $1.ival << "?" << $3.fval << ":" << $5.fval << " -> " << $$.fval;
#endif
		} else {
			LOG(FATAL) << $3.type << " " << $5.type;
		}
	}
;


LOGICAL_OR
: LOGICAL_AND {
		$$ = $1;
#ifdef _DEBUG
		LOG(INFO) << "EQUALITY=" << $$.ival;
#endif
	}
| LOGICAL_OR OP_OR LOGICAL_OR {
		$$.ival = $1.ival || $3.ival;
		$$.type = VT_INT;
#ifdef _DEBUG
		LOG(INFO) << $1.ival << "||" << $3.ival << " -> " << $$.ival;
#endif
	}
;

LOGICAL_AND
: EQUALITY {
		$$ = $1;
#ifdef _DEBUG
		LOG(INFO) << "EQUALITY=" << $$.ival;
#endif
	}
| LOGICAL_AND OP_AND LOGICAL_AND {
		$$.ival = $1.ival && $3.ival;
		$$.type = VT_INT;
#ifdef _DEBUG
		LOG(INFO) << $1.ival << "&&" << $3.ival << " -> " << $$.ival;
#endif
	}
;

EQUALITY
: RELATIONAL {
		$$ = $1;
#ifdef _DEBUG
		LOG(INFO) << "RELATIONAL=" << $$.ival;
#endif
	}
| EQUALITY OP_EQ EQUALITY {
		$$.ival = $1.fval == $3.fval;
		$$.type = VT_INT;
#ifdef _DEBUG
		LOG(INFO) << $1.ival << "==" << $3.ival << " -> " << $$.ival;
#endif
	}
| EQUALITY OP_NE EQUALITY {
		$$.ival = $1.fval == $3.fval;
		$$.type = VT_INT;
#ifdef _DEBUG
		LOG(INFO) << $1.ival << "!=" << $3.ival << " -> " << $$.ival;
#endif
	}

RELATIONAL
: NEGATION {
		$$.ival = $1.ival;
		$$.type = VT_INT;
#ifdef _DEBUG
		LOG(INFO) << "(logical)=" << $$.ival;
#endif
	}
| ADDITIVE OP_LT ADDITIVE {
		$$.ival = (int)($1.fval < $3.fval);
		$$.type = VT_INT;
#ifdef _DEBUG
		LOG(INFO) << $1.fval << "<" << $3.fval << " -> " << $$.ival;
#endif
	}
| ADDITIVE OP_LE ADDITIVE {
		$$.ival = (int)($1.fval <= $3.fval);
		$$.type = VT_INT;
		LOG(INFO) << $1.fval << "<=" << $3.fval << " -> " << $$.ival;
	}
| ADDITIVE OP_GE ADDITIVE {
		$$.ival = (int)($1.fval >= $3.fval);
		$$.type = VT_INT;
#ifdef _DEBUG
		LOG(INFO) << $1.fval << ">=" << $3.fval << " -> " << $$.ival;
#endif
	}
| ADDITIVE OP_GT ADDITIVE {
		$$.ival = (int)($1.fval > $3.fval);
		$$.type = VT_INT;
#ifdef _DEBUG
		LOG(INFO) << $1.fval << ">" << $3.fval << " -> " << $$.ival;
#endif
	}
;

NEGATION
: '!' NEGATION {
		$$.ival = !$2.ival;
		$$.type = VT_INT;
#ifdef _DEBUG
		LOG(INFO) << "!" << $2.ival << " -> " << $$.ival;
#endif
}
| '(' LOGICAL_OR ')' {
		$$.ival = $2.ival;
		$$.type = VT_INT;
#ifdef _DEBUG
		LOG(INFO) << "(LOGICAL_OR)=" << $$.ival;
#endif
	}
;

ADDITIVE
: MULTIPLICATIVE {
		$$ = $1;
#ifdef _DEBUG
		LOG(INFO) << "MULTIPLICATIVE=" << $$.fval;
#endif
	}
| ADDITIVE '+' ADDITIVE {
		$$.fval = $1.fval + $3.fval;
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << $1.fval << "+" << $3.fval << " -> " << $$.fval;
#endif
	}
| ADDITIVE '-' ADDITIVE {
		$$.fval = $1.fval - $3.fval;
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << $1.fval << "-" << $3.fval << " -> " << $$.fval;
#endif
	}
;

MULTIPLICATIVE
: PRIMARY {
		$$ = $1;
#ifdef _DEBUG
		LOG(INFO) << "PRIMARY=" << $$.fval;
#endif
	}
| MULTIPLICATIVE '*' MULTIPLICATIVE {
		$$.fval = $1.fval * $3.fval;
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << $1.fval << "*" << $3.fval << " -> " << $$.fval;
#endif
	}
| MULTIPLICATIVE '/' MULTIPLICATIVE {
		$$.fval = $1.fval / $3.fval;
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << $1.fval << "/" << $3.fval << " -> " << $$.fval;
#endif
	}
;

PRIMARY
: '-' PRIMARY %prec NEG {
		$$.fval = -$2.fval;
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << "-" << $2.fval << "=" << $$.fval;
#endif
	}
| '+' PRIMARY %prec NEG {
		$$.fval = $2.fval;
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << "+" << $2.fval << "=" << $$.fval;
#endif
	}
| CONSTANT {
		$$.fval = $1.fval;
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << "CONSTANT=" << $$.fval;
#endif
	}
| VARIABLE {
		$$.fval = varList[$1.id];
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << "VARIABLE=" << $$.fval;
#endif
	}
| BFUNC '(' CONDITIONAL ',' CONDITIONAL ')' {
		$$.fval = bfuncList[$1.id]($3.fval, $5.fval);
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << "BFUNC" << $1.id << "(" << $3.fval << "," << $5.fval << ") -> " << $$.fval;
#endif
	}
| UFUNC '(' CONDITIONAL ')' {
		$$.fval = ufuncList[$1.id]($3.fval);
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << "UFUNC" << $1.id << "(" << $3.fval << ") -> " << $$.fval;
#endif
	}
| '(' CONDITIONAL ')' {
		$$.fval = $2.fval;
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << "(ADDITIVE)=" << $$.fval;
#endif
	}
;

%%

extern "C" void initialize() {
	varList.clear();
	bfuncList.clear();
	ufuncList.clear();
	namedTokens.clear();

	ADD_UNARY_FUNCTION(log);
	ADD_UNARY_FUNCTION(log10);
	ADD_UNARY_FUNCTION(exp);
	ADD_UNARY_FUNCTION(abs);
	ADD_UNARY_FUNCTION(ceil);
	ADD_UNARY_FUNCTION(floor);
	ADD_UNARY_FUNCTION(cos);
	ADD_UNARY_FUNCTION(cosh);
	ADD_UNARY_FUNCTION(acos);
	ADD_UNARY_FUNCTION(sin);
	ADD_UNARY_FUNCTION(sinh);
	ADD_UNARY_FUNCTION(asin);
	ADD_UNARY_FUNCTION(tan);
	ADD_UNARY_FUNCTION(tanh);
	ADD_UNARY_FUNCTION(atan);
	ADD_UNARY_FUNCTION(sqrt);

	ADD_BINARY_FUNCTION(max);
	ADD_BINARY_FUNCTION(min);
	ADD_BINARY_FUNCTION(atan2);
	ADD_BINARY_FUNCTION(pow);

	// Add mathmatic constants
	namedTokens["e"] = MakeValue(VT_VAR, varList.size());
	varList.push_back(M_E);

	namedTokens["pi"] = MakeValue(VT_VAR, varList.size());
	varList.push_back(M_PI);
}

#define EXPREVAL_NO_ERROR 0
#define EXPREVAL_VAR_ALREADY_SET 1
#define EXPREVAL_VAR_NOT_EXISTS 2

extern "C" const char* format_error_message(int nErrCode) {
	switch (nErrCode) {
	case EXPREVAL_NO_ERROR: return "No error";
	case EXPREVAL_VAR_ALREADY_SET: return "Variable already set";
	case EXPREVAL_VAR_NOT_EXISTS: return "Variable not exists";
	default: break;
	}
	return "Unknown error code";
}

extern "C" int add_variable(const char *pKey, double dValue) {
	int nErrCode = 0;
	std::string strKey = pKey;
	if (namedTokens.count(strKey) == 0) {
		namedTokens[strKey] = MakeValue(VT_VAR, varList.size());
		varList.push_back(dValue);
	} else {
		nErrCode = EXPREVAL_VAR_ALREADY_SET;
	}
	return nErrCode;
}

extern "C" int remove_variable(const char *pKey) {
	int nErrCode = 0;
	auto iVar = namedTokens.find(pKey);
	if (iVar != namedTokens.end() && iVar->second.type == VT_VAR) {
		namedTokens.erase(iVar);
	} else {
		nErrCode = EXPREVAL_VAR_NOT_EXISTS;
	}
	return nErrCode;
}

extern "C" int set_variable_value(const char *pKey, double dValue) {
	int nErrCode = 0;
	auto iVar = namedTokens.find(pKey);
	if (iVar == namedTokens.end()) LOG(INFO) << pKey;
	if (iVar->second.type != VT_VAR) LOG(INFO);
	if (iVar != namedTokens.end() && iVar->second.type == VT_VAR) {
		varList[iVar->second.id] = dValue;
	} else {
		nErrCode = EXPREVAL_VAR_NOT_EXISTS;
	}
	return nErrCode;
}

extern "C" int get_variable_value(const char *pKey, double *pValue) {
	int nErrCode = 0;
	auto iVar = namedTokens.find(pKey);
	if (iVar != namedTokens.end() && iVar->second.type == VT_VAR) {
		*pValue = varList[iVar->second.id];
	} else {
		nErrCode = EXPREVAL_VAR_NOT_EXISTS;
	}
	return nErrCode;
}

inline double evaluate_expr_withcr(const char *pStr, int nLen) {
	auto buffer = yy_scan_bytes(pStr, nLen);
	yyparse();
	yy_delete_buffer(buffer);
	return dResult;
}

extern "C" double evaluate(const char *pStr) {
	int nLen = strlen(pStr);
	if (pStr[nLen - 1] == '\n') {
#ifdef _DEBUG
		LOG(INFO) << "Parsing expression with carriage return...";
#endif
		return evaluate_expr_withcr(pStr, nLen);
	}
	const int nLenThres = 250;
	if (nLen < nLenThres) {
#ifdef _DEBUG
		LOG(INFO) << "Parsing expression without carriage return but within "
				  << nLenThres << " characters...";
#endif
		char buffer[nLenThres + 1];
		memcpy(buffer, pStr, nLen);
		buffer[nLen] = '\n';
		return evaluate_expr_withcr(buffer, nLen + 1);
	}
#ifdef _DEBUG
		LOG(INFO) << "Parsing expression without carriage return and longer than "
				  << nLenThres << " characters...";
#endif
	std::string strExpr = pStr;
	strExpr.push_back('\n');
	return evaluate_expr_withcr(strExpr.c_str(), strExpr.size());
}

static PyObject* initialize_py(PyObject *self) {
	initialize();
	Py_RETURN_NONE;
}

static PyObject* add_variable_py(PyObject *self, PyObject *args) {
	try {
		int nArgCnt = PyTuple_GET_SIZE(args);
		CHECK_GE(nArgCnt, 1) << "The number of arguments be greater or equal to 1";

		PyObject *pyArg0 = PyTuple_GET_ITEM(args, 0);
		CHECK_NOTNULL(pyArg0);
		CHECK(PyUnicode_Check(pyArg0)) << "The first arguments should be a string";
		const char *pKey = PyUnicode_AsUTF8(pyArg0);

		double dValue = 0;
		if (nArgCnt > 1) {
			PyObject *pyArg1 = PyTuple_GET_ITEM(args, 1);
			CHECK_NOTNULL(pyArg1);
			CHECK(PyFloat_Check(pyArg1) || PyLong_Check(pyArg1))
					<< "The second arguments should be a float or int";
			dValue = PyFloat_AsDouble(pyArg1);
		}
		int nRet = add_variable(pKey, dValue);
		CHECK_EQ(nRet, 0) << format_error_message(nRet);

	} catch(const dmlc::Error &e) {
		PyErr_SetString(PyExc_RuntimeError, e.what());
		return NULL;
	}
	Py_RETURN_NONE;
}

static PyObject* remove_variable_py(PyObject *self, PyObject *pyKey) {
	try {
		CHECK(PyUnicode_Check(pyKey)) << "The first arguments hould be a string";
		const char *pKey = PyUnicode_AsUTF8(pyKey);
		int nRet = remove_variable(pKey);
		CHECK_EQ(nRet, 0) << format_error_message(nRet);
	} catch(const dmlc::Error &e) {
		PyErr_SetString(PyExc_RuntimeError, e.what());
		return NULL;
	}
	Py_RETURN_NONE;
}

static PyObject* set_variable_value_py(PyObject *self, PyObject *args) {
	try {
		int nArgCnt = PyTuple_GET_SIZE(args);
		CHECK_EQ(nArgCnt, 2) << "Arguments should be consists of a key (string) "
				"and a value (float)";

		PyObject *pyArg0 = PyTuple_GET_ITEM(args, 0);
		CHECK_NOTNULL(pyArg0);
		CHECK(PyUnicode_Check(pyArg0)) << "The first arguments should be a string";

		PyObject *pyArg1 = PyTuple_GET_ITEM(args, 1);
		CHECK_NOTNULL(pyArg1);
		CHECK(PyFloat_Check(pyArg1) || PyLong_Check(pyArg1))
				<< "The second arguments should be a float or int";

		const char *pKey = PyUnicode_AsUTF8(pyArg0);
		double dValue = PyFloat_AsDouble(pyArg1);
		int nRet = set_variable_value(pKey, dValue);
		CHECK_EQ(nRet, 0) << format_error_message(nRet);

	} catch(const dmlc::Error &e) {
		PyErr_SetString(PyExc_RuntimeError, e.what());
		return NULL;
	}
	Py_RETURN_NONE;
}

static PyObject* get_variable_value_py(PyObject *self, PyObject *pyKey) {
	try {
		CHECK(PyUnicode_Check(pyKey)) << "The first arguments hould be a string";
		const char *pKey = PyUnicode_AsUTF8(pyKey);
		double dValue = 0.;
		int nRet = get_variable_value(pKey, &dValue);
		CHECK_EQ(nRet, 0) << format_error_message(nRet);
	} catch(const dmlc::Error &e) {
		PyErr_SetString(PyExc_RuntimeError, e.what());
		return NULL;
	}
	Py_RETURN_NONE;
}

static PyObject* evaluate_py(PyObject *self, PyObject *pyKey) {
	try {
		CHECK(PyUnicode_Check(pyKey)) << "The first arguments hould be a string";
		const char *pExpr = PyUnicode_AsUTF8(pyKey);
		double dResult = evaluate(pExpr);
	} catch(const dmlc::Error &e) {
		PyErr_SetString(PyExc_RuntimeError, e.what());
		return NULL;
	}
	return PyFloat_FromDouble(dResult);
}

static PyMethodDef methods[] = {
	{
		"initialize",
		(PyCFunction)initialize_py,
		METH_NOARGS,
		"Reset all variable and re-initialize expreval: initialize()"
	},

	{
		"add_variable",
		(PyCFunction)add_variable_py,
		METH_VARARGS,
		"Add an variable with or without a value: add_variable('var1', 1.0)"
	},

	{
		"remove_variable",
		(PyCFunction)remove_variable_py,
		METH_O,
		"Remove a configured variable: remove_variable('var1')"
	},

	{
		"set_variable_value",
		(PyCFunction)set_variable_value_py,
		METH_VARARGS,
		"Set value of a exists variable: set_variable_value('var1', 2.0)"
	},

	{
		"get_variable_value",
		(PyCFunction)get_variable_value_py,
		METH_O,
		"Check wether the specific variable exists: print(get_variable_value('var2'))"
	},

	{
		"evaluate",
		(PyCFunction)evaluate_py,
		METH_O,
		"Evaluate expression: print('2 * (var1 + 1.0)')"
	},

	{ nullptr, nullptr, 0, nullptr }
};

PyMODINIT_FUNC PyInit_libexpreval(void) {
	initialize();
	static PyModuleDef libexpreval_Module = {
			PyModuleDef_HEAD_INIT, "libexpreval", "", -1, methods
		};
	return PyModule_Create(&libexpreval_Module);
}
