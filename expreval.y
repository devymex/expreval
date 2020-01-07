%{
// Expreval: A "C-like" Syntax Expression Evaluator
// Yumeng Wang (devymex@gmail.com)

#include <cmath>
#include <functional>
#include <map>

#include <Python.h>

#include "value.hpp"
#include "logging.hpp"

typedef struct yy_buffer_state *YY_BUFFER_STATE;

extern int yylex();
extern int yyparse();
extern YY_BUFFER_STATE yy_scan_string(const char *str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);

int yyerror(char const *str) {
	extern char *yytext;
	LOG(FATAL) << "parser error near " << yytext << ": " << str << std::endl;
	return 0;
}

std::vector<double> varList;
std::vector<std::function<double(double, double)>> bfuncList;
std::vector<std::function<double(double)>> ufuncList;

std::map<std::string, VALUE> namedValues;

double dResult;

%}

%union {
	VALUE val;
}

%token <val> '+' '-' '*' '/' '?' ':'
%token <val> FUN_MIN FUN_MAX
%token <val> OP_LT OP_LE OP_GE OP_GT
%token <val> OP_EQ OP_NE
%token <val> CR

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

void _initialize() {
	varList.clear();
	bfuncList.clear();
	ufuncList.clear();
	namedValues.clear();

	// Add mathmatic CONSTANTs
	namedValues["e"] = MakeValue(VT_VAR, varList.size());
	varList.push_back(M_E);

	namedValues["pi"] = MakeValue(VT_VAR, varList.size());
	varList.push_back(M_PI);

	// Add binary functions
	namedValues["max"] = MakeValue(VT_BFUNC, bfuncList.size());
	bfuncList.push_back(std::max<double>);

	namedValues["min"] = MakeValue(VT_BFUNC, bfuncList.size());
	bfuncList.push_back(std::min<double>);

	namedValues["atan2"] = MakeValue(VT_BFUNC, bfuncList.size());
	bfuncList.push_back([](double y, double x) { return std::pow(y, x); });

	namedValues["pow"] = MakeValue(VT_BFUNC, bfuncList.size());
	bfuncList.push_back([](double b, double e) { return std::pow(b, e); });

	// Add unary functions
	namedValues["log"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::log(v); });

	namedValues["log10"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::log10(v); });

	namedValues["exp"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::exp(v); });

	namedValues["abs"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::abs(v); });

	namedValues["ceil"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::ceil(v); });

	namedValues["floor"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::floor(v); });

	namedValues["cos"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::cos(v); });

	namedValues["cosh"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::cosh(v); });

	namedValues["acos"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::acos(v); });

	namedValues["sin"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::sin(v); });

	namedValues["sinh"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::sinh(v); });

	namedValues["asin"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::asin(v); });

	namedValues["tan"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::tan(v); });

	namedValues["tanh"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::tanh(v); });

	namedValues["atan"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::atan(v); });

	namedValues["sqrt"] = MakeValue(VT_UFUNC, ufuncList.size());
	ufuncList.push_back([](double v) { return std::sqrt(v); });
}

extern "C" void initialize_py(PyObject *pPyDict) {
	_initialize();

	PyObject *pPyKey, *pPyValue;
	Py_ssize_t pos = 0;

	while (PyDict_Next(pPyDict, &pos, &pPyKey, &pPyValue)) {
		CHECK(PyUnicode_Check(pPyKey));
		CHECK(PyFloat_Check(pPyValue));

		Py_ssize_t nKeyLen;
		const char *pKey = PyUnicode_AsUTF8(pPyKey);
		CHECK_EQ(namedValues.count(pKey), 0) << "Name '"
				<< pKey << "' already exists!";
		namedValues[pKey] = MakeValue(VT_VAR, varList.size());
		varList.push_back(PyFloat_AsDouble(pPyValue));
	}
	Py_XDECREF(pPyDict);
}

extern "C" void initialize(const std::map<std::string, double> &varValues) {
	_initialize();

	for (auto &v : varValues) {
		CHECK_EQ(namedValues.count(v.first), 0) << "Name '"
				<< v.first << "' already exists!";
		namedValues[v.first] = MakeValue(VT_VAR, varList.size());
		varList.push_back(v.second);
	}
}

extern "C" void set_variable_value(const char *pKey, double dValue) {
	auto iFound = namedValues.find(pKey);
	CHECK(iFound != namedValues.end()) << "Key " << pKey << " not found!";
	varList[iFound->second.id] = dValue;
}

extern "C" double evaluate(const char *pStr) {
	std::string strExpr = pStr;
	strExpr.push_back('\n');

	YY_BUFFER_STATE buffer = yy_scan_string(strExpr.c_str());
	yyparse();
	yy_delete_buffer(buffer);

	return dResult;
}

