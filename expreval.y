%{
#include <cmath>
#include <map>

#include <Python.h>

#include "value.hpp"
#include "logging.hpp"

typedef struct yy_buffer_state * YY_BUFFER_STATE;

extern int yylex();
extern int yyparse();
extern YY_BUFFER_STATE yy_scan_string(const char *str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);

int yyerror(char const *str) {
	extern char *yytext;
	LOG(FATAL) << "parser error near " << yytext << ": " << str << std::endl;
	return 0;
}

std::map<std::string, float> varValue;

%}

%union {
	VALUE val;
}

%token <val> constant variable
%token <val> '+' '-' '*' '/' '?' ':'
%token <val> FUN_MIN FUN_MAX
%token <val> CMP_LT CMP_LE CMP_GE CMP_GT
%token <val> CMP_EQ CMP_NE 
%token <val> CR

%type <val> line expr additive multiplicative bfunc primary
%type <val> logical equality relational

%left LOGIC_OR LOGIC_AND
%left CMP_EQ CMP_NE 
%left CMP_LT CMP_LE CMP_GE CMP_GT
%left '+' '-' '*' '/' '?' ':'
%left FUN_MIN FUN_MAX
%precedence NEG

%%

line
: expr CR {
		$$.fval = $1.fval;
		varValue["result"] = $$.fval;
		//LOG(INFO) << "expr=" << $$.fval;
		YYACCEPT;
	}
;

expr
: additive {
		$$.fval = $1.fval;
		//LOG(INFO) << "additive=" << $$.fval;
	}
| logical {
		$$.type = VT_FLOAT;
		$$.fval = (float)$1.ival; 
		//LOG(INFO) << "logical=" << $$.fval;
	}
| logical '?' expr ':' expr {
		if ($3.type == VT_INT && $5.type == VT_INT) {
			$$.type = VT_INT;
			$$.ival = $1.ival ? $3.ival : $5.ival;
			//LOG(INFO) << $1.ival << "?" << $3.ival << ":" << $5.ival << " -> " << $$.ival;
		} else if ($3.type == VT_FLOAT && $5.type == VT_FLOAT) {
			$$.type = VT_FLOAT;
			$$.fval = $1.ival ? $3.fval : $5.fval;
			//LOG(INFO) << $1.ival << "?" << $3.fval << ":" << $5.fval << " -> " << $$.fval;
		} else {
			//LOG(FATAL);
		}
	}
;

logical
: equality {
		$$.ival = $1.ival;
		//LOG(INFO) << "equality=" << $$.ival;
	}
| equality LOGIC_OR equality {
		$$.ival = $1.ival || $3.ival;
		//LOG(INFO) << $1.ival << "||" << $3.ival << " -> " << $$.ival;
	}
| equality LOGIC_AND equality {
		$$.ival = $1.ival && $3.ival;
		//LOG(INFO) << $1.ival << "&&" << $3.ival << " -> " << $$.ival;
	}
;

equality
: relational {
		$$.ival = $1.ival; 
		//LOG(INFO) << "relational=" << $$.ival;
	}
| relational CMP_EQ relational {
		$$.ival = $1.fval == $3.fval;
		//LOG(INFO) << $1.ival << "==" << $3.ival << " -> " << $$.ival;
	}
| relational CMP_NE relational {
		$$.ival = $1.fval == $3.fval; 
		//LOG(INFO) << $1.ival << "!=" << $3.ival << " -> " << $$.ival;
	}

relational
: additive CMP_LT additive {
		$$.ival = (int)($1.fval < $3.fval);
		$$.type = VT_INT;
		//LOG(INFO) << $1.fval << "<" << $3.fval << " -> " << $$.ival;
	}
| additive CMP_LE additive {
		$$.ival = (int)($1.fval <= $3.fval);
		$$.type = VT_INT;
		//LOG(INFO) << $1.fval << "<=" << $3.fval << " -> " << $$.ival;
	}
| additive CMP_GE additive {
		$$.ival = (int)($1.fval >= $3.fval);
		$$.type = VT_INT;
		//LOG(INFO) << $1.fval << ">=" << $3.fval << " -> " << $$.ival;
	}
| additive CMP_GT additive {
		$$.ival = (int)($1.fval > $3.fval);
		$$.type = VT_INT;
		//LOG(INFO) << $1.fval << ">" << $3.fval << " -> " << $$.ival;
	}
;

additive
: multiplicative {
		$$.fval = $1.fval;
		//LOG(INFO) << "multiplicative=" << $$.fval;
	}
| multiplicative '+' multiplicative {
		$$.fval = $1.fval + $3.fval;
		//LOG(INFO) << $1.fval << "+" << $3.fval << " -> " << $$.fval;
	}
| multiplicative '-' multiplicative {
		$$.fval = $1.fval - $3.fval;
		//LOG(INFO) << $1.fval << "-" << $3.fval << " -> " << $$.fval;
	}
;

multiplicative
: primary {
		$$.fval = $1.fval;
		//LOG(INFO) << "primary=" << $$.fval;
	}
| primary '*' primary {
		$$.fval = $1.fval * $3.fval;
		//LOG(INFO) << $1.fval << "*" << $3.fval << " -> " << $$.fval;
	}
| primary '/' primary {
		$$.fval = $1.fval / $3.fval;
		//LOG(INFO) << $1.fval << "/" << $3.fval << " -> " << $$.fval;
	}
;

bfunc
: FUN_MIN '(' expr ',' expr ')' {
		$$.fval = std::min($3.fval, $5.fval);
		//LOG(INFO) << "min(" << $3.fval << "," << $5.fval << ") -> " << $$.fval;
	}
| FUN_MAX '(' expr ',' expr ')' {
		$$.fval = std::max($3.fval, $5.fval);
		//LOG(INFO) << "max(" << $3.fval << "," << $5.fval << ") -> " << $$.fval;
	}
;

primary
: '-' primary %prec NEG {
		$$.fval = -$1.fval; 
	}
| constant {
		$$.fval = $1.fval; 
		$$.type = VT_FLOAT;
		//LOG(INFO) << "constant=" << $$.fval;
	}
| variable {
		$$.fval = $1.fval; 
		$$.type = VT_FLOAT;
		//LOG(INFO) << "variable=" << $$.fval;
	}
| bfunc {
		$$ = $1;
		//LOG(INFO) << "bfunc=" << $$.fval;
	}
| '(' expr ')' {
		$$.fval = $2.fval;
		//LOG(INFO) << "(expr)=" << $$.fval;
	}
;

%%

extern "C" void set_variables_py(PyObject *pPyDict) {
	PyObject *pPyKey, *pPyValue;
	Py_ssize_t pos = 0;

	while (PyDict_Next(pPyDict, &pos, &pPyKey, &pPyValue)) {
		CHECK(PyUnicode_Check(pPyKey));
		CHECK(PyFloat_Check(pPyValue));

		Py_ssize_t nKeyLen;
		const char *pKey = PyUnicode_AsUTF8(pPyKey);
		CHECK_EQ(pKey[0], '_') << "Variable name must start with '_'";
		double dVal = PyFloat_AsDouble(pPyValue);
		varValue[pKey] = (float)dVal;

		Py_XDECREF(pPyKey);
		Py_XDECREF(pPyValue);
	}
	Py_XDECREF(pPyDict);
}

extern "C" void set_variables(const std::map<std::string, float> &varMap) {
	for (auto &v : varMap) {
		CHECK_EQ(v.first[0], '_') << "Variable name must start with '_'";
	}
	varValue = varMap;
}

extern "C" double evaluate(const char *pStr) {
	std::string strExpr = pStr;
	strExpr.push_back('\n');
	
	YY_BUFFER_STATE buffer = yy_scan_string(strExpr.c_str());
	yyparse();
	yy_delete_buffer(buffer);

	double dRet = varValue["result"];
	return dRet;
}

