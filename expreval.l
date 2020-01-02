%{
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
(_[a-zA-Z0-9]+) {
	auto iVar = varValue.find(yytext);
	CHECK(iVar != varValue.end()) << yytext;
	yylval.val.fval = iVar->second;
	return variable;
}
[\+\-] {return *yytext;}
[\*\/] {return *yytext;}
[\(\)\?\:\,] {return *yytext;}

"min" {return FUN_MIN;}
"max" {return FUN_MAX;}

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
	LOG(FATAL) << "Lex error!";
}
%%

