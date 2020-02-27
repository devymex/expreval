%option noinput nounput noyywrap 8bit nodefault
%option yylineno
%option reentrant bison-bridge bison-locations
%option extra-type="struct EXPREVAL *"

%{
// Expreval: A "C-like" Syntax Expression Evaluator
// Yumeng Wang (devymex@gmail.com)

#include <vector>
#include <functional>
#include <unistd.h>

#include "value.hpp"
#include "y.tab.h"
#include "logging.hpp"

%}

%%

[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)? {
	yylval->val.fval = atof(yytext);
	return CONSTANT;
}
([a-zA-Z_][a-zA-Z0-9_]*) {
	auto iValue = yyextra->namedTokens.find(yytext);
	CHECK(iValue != yyextra->namedTokens.end()) << "Name '"
			<< yytext << "' not recognized!";
	switch (iValue->second.type) {
	case VT_VAR:
		yylval->val.fval = yyextra->varList[iValue->second.id];
		return VARIABLE;
	case VT_BFUNC:
		yylval->val.bfunc = &(yyextra->bfuncList[iValue->second.id]);
		return BFUNC;
	case VT_UFUNC:
		yylval->val.ufunc = &(yyextra->ufuncList[iValue->second.id]);
		return UFUNC;
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
