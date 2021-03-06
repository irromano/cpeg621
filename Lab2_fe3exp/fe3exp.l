%{
#include <stdlib.h> /* for atoi call */
#include <stdio.h>
#include <string.h>	/* for sscanf */
#include "fe3exp.tab.h"

//#define DEBUG /* for debuging: print tokens and their line numbers */
//#define NUMBER 258 /* copy this from cal.tab.c */

//YYSTYPE yylval; /* for passing value to parser */
extern int lineNum; /* line number from cal.tab.c */
extern char *yytext;

%}

%%
[ \t]+ {}

[\n] { 
		lineNum++;
		return '\n';
	 }

"=" {
	#ifdef DEBUG
	printf("token '=' at line %d\n", lineNum);
	#endif
	return '=';
	}

"+" {
	#ifdef DEBUG
	printf("token '+' at line %d\n", lineNum);
	#endif
	return '+';
	}
	
"-" {
	#ifdef DEBUG
	printf("token '-' at line %d\n", lineNum);
	#endif
	return '-';
	}
"*" {
	#ifdef DEBUG
	printf("token '*' at line %d\n", lineNum);
	#endif
	return '*';
	}

"/" {
	#ifdef DEBUG
	printf("token '/' at line %d\n", lineNum);
	#endif
	return '/';
	}

"**" {
	#ifdef DEBUG
	printf("token \"**\" at line %d\n", lineNum);
	#endif
	return POW;
	}

"(" {
	#ifdef DEBUG
	printf("token '(' at line %d\n", lineNum);
	#endif
	return '(';
	}

")" {
	#ifdef DEBUG
	printf("token ')' at line %d\n", lineNum);
	#endif
	return ')';
	}

"!" {
	#ifdef DEBUG
	printf("token '!' at line %d\n", lineNum);
	#endif
	return '!';
	}

"?" {
	#ifdef DEBUG
	printf("token '?' at line %d\n", lineNum);
	#endif
	return '?';
	}

[0-9]+ {
	#ifdef DEBUG
	printf("token %s at line %d\n", yytext, lineNum);
	#endif	
	yylval.d = atoi(yytext);
	return NUMBER;
	}

[a-zA-Z][a-zA-Z0-9]*	{
	#ifdef DEBUG
	printf("token %s at line %d\n", yytext, lineNum);
	#endif
	sscanf(yytext, "%s", yylval.name);
	return TEXT;
}

%%
int yywrap() { /* need this to avoid link problem */
	return 1;
}
