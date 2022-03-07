%{
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include <stdbool.h>

#define DEBUG /* for debuging: print production results */
int lineNum = 1;

void yyerror(char *ps, ...) 
{ /* need this to avoid link problem */
	printf("%s\n", ps);
}

%}

%code requires {
#define STRINGLENGTH 100

}

%union {
	char name[STRINGLENGTH];
	int d;
	struct nodeVar *nPtr;
}

// need to choose token type from union above
%token <name> NUMBER
%token QUIT
%right '='
%token '(' ')'
%left '+' '-'
%left '*' '/'
%right POW
%right '!'
%type <name> exp factor term
%right '\n'
%start prefix

%%
prefix : exp '\n'
	{ 
		printf("%s\n", $1);
	}
	| prefix exp '\n'
	{ 
		printf("%s\n", $2);
	}
	| prefix '\n'
	{
		#ifdef DEBUG
		printf("Blank '\\n' found\n");
		#endif
	}
	| '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	}
	| prefix '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	}
	| '!' '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	}
	| prefix '!' '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	};

exp : exp '+' factor
	{ 
		strcpy($$, "+ ");
		strcat($$, $1);
		strcat($$, " ");
		strcat($$, $3);
		strcat($$, " ");

		#ifdef DEBUG
		printf("exp %s : exp %s + factor %s\n", $$, $1, $3);
		#endif
	}
	| exp '-' factor
	{ 
		strcpy($$, "- ");
		strcat($$, $1);
		strcat($$, " ");
		strcat($$, $3);
		strcat($$, " ");

		#ifdef DEBUG
		printf("exp %s : exp %s - factor %s\n", $$, $1, $3);
		#endif
	}
    | factor
	{ 
		strcpy($$, $1);
		#ifdef DEBUG
		printf("exp %s : factor %s\n", $$, $1);
		#endif
	};

factor : factor '*' term
	{ 
		strcpy($$, "* ");
		strcat($$, $1);
		strcat($$, " ");
		strcat($$, $3);
		strcat($$, " ");


		#ifdef DEBUG
		printf("factor %s : factor %s * term %s\n", $$, $1, $3);
		#endif
	}
	| factor '/' term
	{ 
		strcpy($$, "/ ");
		strcat($$, $1);
		strcat($$, " ");
		strcat($$, $3);
		strcat($$, " ");

		#ifdef DEBUG
		printf("factor %s : factor %s / term %s\n", $$, $1, $3);
		#endif
	}
	| factor POW term
	{
		strcpy($$, "** ");
		strcat($$, $1);
		strcat($$, " ");
		strcat($$, $3);
		strcat($$, " ");
		#ifdef DEBUG
		printf("term %s: %s ** %s\n", $$, $1, $3);
		#endif
	}
       | term
	{
		strcpy($$, $1);
		#ifdef DEBUG
		printf("factor %s : term %s\n", $$, $1);
		#endif
	}
	| '!' factor
	{
		strcpy($$, "!");
		strcat($$, $2);
		strcat($$, " ");
	}
	;

term : NUMBER
	{ 
		strcpy($$, $1);
		#ifdef DEBUG
		printf("term %s : number %s\n", $$, $1);
		#endif
	}
     | '(' exp ')'
	{
		strcpy($$, $2);
		#ifdef DEBUG
		printf("term %s : (exp) %s\n", $$, $2);
		#endif
	}
	
	| NUMBER '=' exp
	{
		strcpy($$, "= ");
		strcat($$, $1);
		strcat($$, " ");
		strcat($$, $3);
		strcat($$, " ");
	}
	;

%%

int main() {
	yyparse();
	return 0;
}
