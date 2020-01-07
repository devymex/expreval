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
	return CONSTANT;
}
([a-zA-Z_][a-zA-Z0-9_]*) {
	auto iValue = namedValues.find(yytext);
	CHECK(iValue != namedValues.end()) << "Name '"
			<< yytext << "' not recognized!";
	yylval.val = iValue->second;
	switch (iValue->second.type) {
	case VT_VAR: return VARIABLE;
	case VT_BFUNC: return BFUNC;
	case VT_UFUNC: return UFUNC;
	default: break;
	}
	LOG(FATAL);
}
[\+\-\*\/\(\)\?\:\,\!] {return *yytext;}
"<"		{return OP_LT;}
">"		{return OP_GT;}
"<="	{return OP_LE;}
">="	{return OP_GE;}
"=="	{return OP_EQ;}
"!="	{return OP_NE;}
"||"	{return OP_OR;}
"&&"	{return OP_AND;}
"\n"	{return CR;}
[ \t]	;
.		{LOG(FATAL) << "Lex error: " << yytext;}

%%

