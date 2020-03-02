%define api.pure full

%param {

yyscan_t scanner

} // %param {

%code top {

#include <cmath>
#include <Python.h>
#include "value.hpp"
#include "logging.hpp"

} // %code top {

%code requires {

using yyscan_t = void *;
using YY_BUFFER_STATE = struct yy_buffer_state *;
using YY_EXTRA_TYPE = struct EXPREVAL *;
using EXPREVAL_HANDLE = void *;

} // %code requires {

%code provides {

// Expreval: A "C-like" Syntax Expression Evaluator
// Yumeng Wang (devymex@gmail.com)

#define EXPREVAL_NO_ERROR 0
#define EXPREVAL_VAR_ALREADY_SET 1
#define EXPREVAL_VAR_NOT_EXISTS 2

// Statement of generated functions by lex
// ---------------------------------------
int yylex_init_extra(YY_EXTRA_TYPE user_defined, yyscan_t *yyscanner);
int yylex_destroy(yyscan_t yyscanner);

YY_BUFFER_STATE yy_scan_bytes(const char *yybytes,
		int _yybytes_len, yyscan_t yyscanner);
void yy_delete_buffer(YY_BUFFER_STATE buffer, yyscan_t yyscanner);

int yylex(YYSTYPE* yylvalp, yyscan_t scanner);

YYSTYPE * yyget_lval(yyscan_t yyscanner);
YY_EXTRA_TYPE yyget_extra(yyscan_t yyscanner);

// Statement of error handler
// --------------------------
extern "C" int yyerror(yyscan_t, const char* msg);

} // %code provides {

%union {
	VALUE val;
}

%token <val> '+' '-' '*' '/' '?' ':'
%token <val> OP_LT OP_LE OP_GE OP_GT OP_EQ OP_NE
%token <val> CONSTANT VARIABLE BFUNC UFUNC
%token <val> END_OF_FILE

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
: CONDITIONAL END_OF_FILE {
		$$ = $1;
		auto pExpr = yyget_extra(scanner);
		pExpr->dResult = $$.fval;
#ifdef _DEBUG
		LOG(INFO) << "CONDITIONAL=" << pExpr->dResult;
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
		$$.fval = $1.fval;
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << "VARIABLE=" << $$.fval;
#endif
	}
| BFUNC '(' CONDITIONAL ',' CONDITIONAL ')' {
		auto &bfunc = *$1.bfunc;
		$$.fval = bfunc($3.fval, $5.fval);
		$$.type = VT_FLOAT;
#ifdef _DEBUG
		LOG(INFO) << "BFUNC" << $1.id << "(" << $3.fval << "," << $5.fval << ") -> " << $$.fval;
#endif
	}
| UFUNC '(' CONDITIONAL ')' {
		auto &ufunc = *$1.ufunc;
		$$.fval = ufunc($3.fval);
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

#define ADD_UNARY_FUNCTION(func_name) \
	pExpr->namedTokens[#func_name] = MakeValue(VT_UFUNC, pExpr->ufuncList.size()); \
	pExpr->ufuncList.push_back([](double v) { return std::func_name(v); });

#define ADD_BINARY_FUNCTION(func_name) \
	pExpr->namedTokens[#func_name] = MakeValue(VT_BFUNC, pExpr->bfuncList.size()); \
	pExpr->bfuncList.push_back([](double a, double b) { return std::func_name(a, b); });

extern "C" EXPREVAL_HANDLE initialize() {
	EXPREVAL_HANDLE pExprHdl = new EXPREVAL;

	EXPREVAL *pExpr = (EXPREVAL*)pExprHdl;

	yylex_init_extra(pExpr, &(pExpr->pScannerHdl));

	pExpr->varList.clear();
	pExpr->bfuncList.clear();
	pExpr->ufuncList.clear();
	pExpr->namedTokens.clear();

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
	pExpr->namedTokens["e"] = MakeValue(VT_VAR, pExpr->varList.size());
	pExpr->varList.push_back(M_E);

	pExpr->namedTokens["pi"] = MakeValue(VT_VAR, pExpr->varList.size());
	pExpr->varList.push_back(M_PI);
	return pExprHdl;
}

extern "C" void unintialize(EXPREVAL_HANDLE pExprHdl) {
	EXPREVAL *pExpr = (EXPREVAL*)pExprHdl;

	yylex_destroy(pExpr->pScannerHdl);
	delete pExpr;
}

extern "C" int add_variable(EXPREVAL_HANDLE pExprHdl,
		const char *pKey, double dValue) {
	EXPREVAL *pExpr = (EXPREVAL*)pExprHdl;

	int nErrCode = 0;
	std::string strKey = pKey;
	if (pExpr->namedTokens.count(strKey) == 0) {
		pExpr->namedTokens[strKey] = MakeValue(VT_VAR, pExpr->varList.size());
		pExpr->varList.push_back(dValue);
	} else {
		nErrCode = EXPREVAL_VAR_ALREADY_SET;
	}
	return nErrCode;
}

extern "C" int remove_variable(EXPREVAL_HANDLE pExprHdl, const char *pKey) {
	EXPREVAL *pExpr = (EXPREVAL*)pExprHdl;

	int nErrCode = 0;
	auto iVar = pExpr->namedTokens.find(pKey);
	if (iVar != pExpr->namedTokens.end() && iVar->second.type == VT_VAR) {
		pExpr->namedTokens.erase(iVar);
	} else {
		nErrCode = EXPREVAL_VAR_NOT_EXISTS;
	}
	return nErrCode;
}

extern "C" int set_variable_value(EXPREVAL_HANDLE pExprHdl,
		const char *pKey, double dValue) {
	EXPREVAL *pExpr = (EXPREVAL*)pExprHdl;

	int nErrCode = 0;
	auto iVar = pExpr->namedTokens.find(pKey);
	if (iVar == pExpr->namedTokens.end()) LOG(INFO) << pKey;
	if (iVar->second.type != VT_VAR) LOG(INFO);
	if (iVar != pExpr->namedTokens.end() && iVar->second.type == VT_VAR) {
		pExpr->varList[iVar->second.id] = dValue;
	} else {
		nErrCode = EXPREVAL_VAR_NOT_EXISTS;
	}
	return nErrCode;
}

extern "C" int get_variable_value(EXPREVAL_HANDLE pExprHdl,
		const char *pKey, double *pValue) {
	EXPREVAL *pExpr = (EXPREVAL*)pExprHdl;

	int nErrCode = 0;
	auto iVar = pExpr->namedTokens.find(pKey);
	if (iVar != pExpr->namedTokens.end() && iVar->second.type == VT_VAR) {
		*pValue = pExpr->varList[iVar->second.id];
	} else {
		nErrCode = EXPREVAL_VAR_NOT_EXISTS;
	}
	return nErrCode;
}

extern "C" double evaluate_with_length(EXPREVAL_HANDLE pExprHdl,
		const char *pStr, int nLen) {
	EXPREVAL *pExpr = (EXPREVAL*)pExprHdl;

	auto buffer = yy_scan_bytes(pStr, nLen, pExpr->pScannerHdl);
	yyparse(pExpr->pScannerHdl);
	double dResult = pExpr->dResult;
	yy_delete_buffer(buffer, pExpr->pScannerHdl);
	return dResult;
}

extern "C" double evaluate(EXPREVAL_HANDLE pExprHdl, const char *pStr) {
	int nLen = strlen(pStr);
	return evaluate_with_length(pExprHdl, pStr, nLen);
}

extern "C" const char* format_error_message(int nErrCode) {
	switch (nErrCode) {
	case EXPREVAL_NO_ERROR: return "No error";
	case EXPREVAL_VAR_ALREADY_SET: return "Variable already set";
	case EXPREVAL_VAR_NOT_EXISTS: return "Variable not exists";
	default: break;
	}
	return "Unknown error code";
}

extern "C" int yyerror(yyscan_t, const char* msg) {
	LOG(FATAL) << msg << std::endl;
	return 0;
}
