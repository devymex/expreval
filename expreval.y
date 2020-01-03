%{
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
%token <val> CMP_LT CMP_LE CMP_GE CMP_GT
%token <val> CMP_EQ CMP_NE 
%token <val> CR

%token <val> constant variable bfunc ufunc
%type <val> line expr additive multiplicative primary
%type <val> logical equality relational

%left LOGIC_OR LOGIC_AND
%left CMP_EQ CMP_NE 
%left CMP_LT CMP_LE CMP_GE CMP_GT
%left '+' '-' '*' '/' '?' ':'
%precedence NEG

%%

line
: expr CR {
		$$.fval = $1.fval;
		$$.type = VT_FLOAT;

		dResult = $$.fval;
		LOG(INFO) << "expr=" << $$.fval;
		YYACCEPT;
	}
;

expr
: additive {
		$$.fval = $1.fval;
		$$.type = VT_FLOAT;
		LOG(INFO) << "additive=" << $$.fval;
	}
| logical {
		$$.fval = (double)$1.ival; 
		$$.type = VT_FLOAT;
		LOG(INFO) << "logical=" << $$.fval;
	}
| logical '?' expr ':' expr {
		if ($3.type == VT_INT && $5.type == VT_INT) {
			$$.ival = $1.ival ? $3.ival : $5.ival;
			$$.type = VT_INT;
			LOG(INFO) << $1.ival << "?" << $3.ival << ":" << $5.ival << " -> " << $$.ival;
		} else if ($3.type == VT_FLOAT && $5.type == VT_FLOAT) {
			$$.fval = $1.ival ? $3.fval : $5.fval;
			$$.type = VT_FLOAT;
			LOG(INFO) << $1.ival << "?" << $3.fval << ":" << $5.fval << " -> " << $$.fval;
		} else {
			LOG(FATAL) << $3.type << " " << $5.type;
		}
	}
;

logical
: equality {
		$$.ival = $1.ival;
		$$.type = VT_INT;
		LOG(INFO) << "equality=" << $$.ival;
	}
| equality LOGIC_OR equality {
		$$.ival = $1.ival || $3.ival;
		$$.type = VT_INT;
		LOG(INFO) << $1.ival << "||" << $3.ival << " -> " << $$.ival;
	}
| equality LOGIC_AND equality {
		$$.ival = $1.ival && $3.ival;
		$$.type = VT_INT;
		LOG(INFO) << $1.ival << "&&" << $3.ival << " -> " << $$.ival;
	}
;

equality
: relational {
		$$.ival = $1.ival; 
		LOG(INFO) << "relational=" << $$.ival;
		$$.type = VT_INT;
	}
| relational CMP_EQ relational {
		$$.ival = $1.fval == $3.fval;
		$$.type = VT_INT;
		LOG(INFO) << $1.ival << "==" << $3.ival << " -> " << $$.ival;
	}
| relational CMP_NE relational {
		$$.ival = $1.fval == $3.fval; 
		$$.type = VT_INT;
		LOG(INFO) << $1.ival << "!=" << $3.ival << " -> " << $$.ival;
	}

relational
: additive CMP_LT additive {
		$$.ival = (int)($1.fval < $3.fval);
		$$.type = VT_INT;
		LOG(INFO) << $1.fval << "<" << $3.fval << " -> " << $$.ival;
	}
| additive CMP_LE additive {
		$$.ival = (int)($1.fval <= $3.fval);
		$$.type = VT_INT;
		LOG(INFO) << $1.fval << "<=" << $3.fval << " -> " << $$.ival;
	}
| additive CMP_GE additive {
		$$.ival = (int)($1.fval >= $3.fval);
		$$.type = VT_INT;
		LOG(INFO) << $1.fval << ">=" << $3.fval << " -> " << $$.ival;
	}
| additive CMP_GT additive {
		$$.ival = (int)($1.fval > $3.fval);
		$$.type = VT_INT;
		LOG(INFO) << $1.fval << ">" << $3.fval << " -> " << $$.ival;
	}
;

additive
: multiplicative {
		$$.fval = $1.fval;
		$$.type = VT_FLOAT;
		LOG(INFO) << "multiplicative=" << $$.fval;
	}
| multiplicative '+' multiplicative {
		$$.fval = $1.fval + $3.fval;
		$$.type = VT_FLOAT;
		LOG(INFO) << $1.fval << "+" << $3.fval << " -> " << $$.fval;
	}
| multiplicative '-' multiplicative {
		$$.fval = $1.fval - $3.fval;
		$$.type = VT_FLOAT;
		LOG(INFO) << $1.fval << "-" << $3.fval << " -> " << $$.fval;
	}
;

multiplicative
: primary {
		$$ = $1;
		LOG(INFO) << "primary=" << $$.fval;
	}
| primary '*' primary {
		$$.fval = $1.fval * $3.fval;
		$$.type = VT_FLOAT;
		LOG(INFO) << $1.fval << "*" << $3.fval << " -> " << $$.fval;
	}
| primary '/' primary {
		$$.fval = $1.fval / $3.fval;
		$$.type = VT_FLOAT;
		LOG(INFO) << $1.fval << "/" << $3.fval << " -> " << $$.fval;
	}
;

primary
: '-' primary %prec NEG {
		$$.fval = -$2.fval; 
		LOG(INFO) << "-(" << $2.fval << ")=" << $$.fval;
	}
| constant {
		$$.fval = $1.fval; 
		$$.type = VT_FLOAT;
		LOG(INFO) << "constant=" << $$.fval;
	}
| variable {
		$$.fval = varList[$1.id]; 
		$$.type = VT_FLOAT;
		LOG(INFO) << "variable=" << $$.fval;
	}
| bfunc '(' expr ',' expr ')' {
		$$.fval = bfuncList[$1.id]($3.fval, $5.fval);
		$$.type = VT_FLOAT;
		LOG(INFO) << "bfunc" << $1.id << "(" << $3.fval << "," << $5.fval << ") -> " << $$.fval;
	}
| ufunc '(' expr ')' {
		$$.fval = ufuncList[$1.id]($3.fval);
		$$.type = VT_FLOAT;
		LOG(INFO) << "ufunc" << $1.id << "(" << $3.fval << ") -> " << $$.fval;
	}
| '(' expr ')' {
		$$.fval = $2.fval;
		$$.type = VT_FLOAT;
		LOG(INFO) << "(expr)=" << $$.fval;
	}
;

%%

void _initialize() {
	varList.clear();
	bfuncList.clear();
	ufuncList.clear();
	namedValues.clear();

	namedValues["max"] = MakeValue(VT_BFUNC, bfuncList.size());
	bfuncList.push_back(std::max<double>);

	namedValues["min"] = MakeValue(VT_BFUNC, bfuncList.size());
	bfuncList.push_back(std::min<double>);

	namedValues["atan2"] = MakeValue(VT_BFUNC, bfuncList.size());
	bfuncList.push_back([](double y, double x) { return std::pow(y, x); });

	namedValues["pow"] = MakeValue(VT_BFUNC, bfuncList.size());
	bfuncList.push_back([](double b, double e) { return std::pow(b, e); });

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

		Py_XDECREF(pPyKey);
		Py_XDECREF(pPyValue);
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

extern "C" double evaluate(const char *pStr) {
	std::string strExpr = pStr;
	strExpr.push_back('\n');
	
	YY_BUFFER_STATE buffer = yy_scan_string(strExpr.c_str());
	yyparse();
	yy_delete_buffer(buffer);

	return dResult;
}

