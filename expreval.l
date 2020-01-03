
%{
// Expreval: A "C-like" Syntax Expression Evaluator
// Yumeng Wang (devymex@gmail.com)

#include "value.hpp"
#include "y.tab.h"
#include "logging.hpp"

extern "C" int yywrap(void) {
	return 1;
}
%}

%%

[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)? {
	yylval.val.fval = atof(yytext);
	return constant;
}
([a-zA-Z_][a-zA-Z0-9]*) {
	auto iValue = namedValues.find(yytext);
	CHECK(iValue != namedValues.end()) << "Name '"
			<< yytext << "' not recognized!";
	yylval.val = iValue->second;
	switch (iValue->second.type) {
	case VT_VAR: return variable;
	case VT_BFUNC: return bfunc;
	case VT_UFUNC: return ufunc;
	default: break;
	}
	LOG(FATAL);
}
[\+\-\*\/\(\)\?\:\,] {return *yytext;}
"<" {return CMP_LT;}
"<=" {return CMP_LE;}
">=" {return CMP_GE;}
">" {return CMP_GT;}

"==" {return CMP_EQ;}
"!=" {return CMP_NE;}

"||" {return LOGIC_OR;}
"&&" {return LOGIC_AND;}

"\n" {return CR;}
[ \t] ;

. {
	LOG(FATAL) << "Lex error: " << yytext;
}
%%

