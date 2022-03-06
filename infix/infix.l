%{
#include <stdlib.h> /* for atoi call */
#include <string.h>	/* for sscanf */
#include "infix.tab.h"

#define DEBUG /* for debuging: print tokens and their line numbers */
//#define NUMBER 258 /* copy this from cal.tab.c */

// typedef union { /* copy this from cal.tab.c */
// int d;
// } YYSTYPE;

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

"quit()" {
	#ifdef DEBUG
	printf("token 'quit()' at line %d\n", lineNum);
	#endif
	return QUIT;
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

[0-9]+ {
	#ifdef DEBUG
	printf("token %s at line %d\n", yytext, lineNum);
	#endif
	yylval.d = atoi(yytext);
	return NUMBER;
	}

[a-z][a-zA-Z0-9]+	{
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
