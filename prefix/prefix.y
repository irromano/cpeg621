%{
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include <stdbool.h>

// #define DEBUG /* for debuging: print production results */
int lineNum = 1;

/* prototype functions */
struct nodeVar* assignVar(char *name, int val);
struct nodeVar* findVar(char *name, int val, struct nodeVar *var);
struct nodeVar* newVar(char* name, int val);
void pushStackText(char* text);
void pushStackVal(int val);
void popEntireStack();
void yyerror(char *ps, ...) 
{ /* need this to avoid link problem */
	printf("%s\n", ps);
}

struct nodeVar *head;
struct nodeVar *stack;

bool first;

%}

%code requires {
#define STRINGLENGTH 100
	struct nodeVar
	{
		char text[STRINGLENGTH];
		int val;
		struct nodeVar *next;
	} nodeVar;
}

%union {
	char name[STRINGLENGTH];
	int d;
	struct nodeVar *nPtr;
}

// need to choose token type from union above
%token <d> NUMBER
%token <name> TEXT
%token QUIT
%right '='
%token '(' ')'
%left '+' '-'
%left '*' '/'
%right POW
%right '!'
%type <d> exp factor term
%right '\n'
%start prefix

%%
prefix : exp '\n'
	{ 
		popEntireStack();
	}
	| prefix exp '\n'
	{ 
		popEntireStack();
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
		if (first)
			pushStackVal($3);
		pushStackVal($1);
		pushStackText("+");
		$$ = $1 + $3;
		#ifdef DEBUG
		printf("exp %d : exp %d + factor %d\n", $$, $1, $3);
		#endif
	}
	| exp '-' factor
	{ 
		$$ = $1 - $3;
		#ifdef DEBUG
		printf("exp %d : exp %d - factor %d\n", $$, $1, $3);
		#endif
	}
    | factor
	{ 
		$$ = $1;
		#ifdef DEBUG
		printf("exp %d : factor %d\n", $$, $1);
		#endif
	};

factor : factor '*' term
	{ 
		if (first)
			pushStackVal($3);
		pushStackVal($1);
		pushStackText("*");
		$$ = $1 * $3; 
		#ifdef DEBUG
		printf("factor %d : factor %d * term %d\n", $$, $1, $3);
		#endif
	}
	| factor '/' term
	{ 
		$$ = $1 / $3; 
		#ifdef DEBUG
		printf("factor %d : factor %d / term %d\n", $$, $1, $3);
		#endif
	}
       | term
	{
		$$ = $1;
		#ifdef DEBUG
		printf("factor %d : term %d\n", $$, $1);
		#endif
	}
	| '!' factor
	{
		if (first)
			pushStackVal($2);
		pushStackText("!");
		$$ = $2;
	}
	;

term : NUMBER
	{ 
		$$ = $1;
		#ifdef DEBUG
		printf("term %d : number %d\n", $$, $1);
		#endif
	}
     | '(' exp ')'
	{
		$$ = $2;
		#ifdef DEBUG
		printf("term %d : (exp) %d\n", $$, $2);
		#endif
	}
	| TEXT
	{
		$$ = 0;
		#ifdef DEBUG
		printf("variable %s is %d\n", $1, node->val);
		#endif
	}
	| factor POW term
	{
		int num = 1;
		for (int i=0; i<$3; i++)
		{
			num *= $1;
		}
		$$ = num;
		#ifdef DEBUG
		printf("term %d: %d ** %d\n", $$, $1, $3);
		#endif
	}
	
	| TEXT '=' exp
	{
		if (first)
			pushStackVal($3);
		pushStackText($1);
		pushStackText("=");
		$$ = $3;
	}
	;

%%

struct nodeVar* assignVar(char *name, int val)
{
	struct nodeVar *var = findVar(name, val, head);
	var->val = val;
	return var;
}

struct nodeVar* findVar(char *name, int val, struct nodeVar *var)
{
	if(strcmp(name, var->text) == 0)
	{
		return var;
	}
	else if (var->next == NULL)
	{
		var->next = newVar(name, val);
		return var->next;
	}
	else
	{
		return findVar(name, val, var->next);
	}
	
}

struct nodeVar* newVar(char* name, int val)
{
	struct nodeVar* var = (struct nodeVar*) malloc(sizeof(struct nodeVar));
	sscanf(name, "%s", var->text);
	var->val = val;
	var->next = NULL;
	return var; 
}

void freeNodes()
{
	#ifdef DEBUG
	printf("Freeing all variable Nodes\n");
	#endif
	struct nodeVar *node = head->next;
	while(node != NULL)
	{
		struct nodeVar *tmp = node->next;
		free(node);
		node = tmp;
	}

	return;
}

void pushStackText(char* text)
{
	first = false;
	for (int i=0; i<STRINGLENGTH; i++)
	{
		stack->text[i] = '\0';
	}
	sscanf(text, "%s", stack->text);
	stack->val = 0;
	struct nodeVar* temp = (struct nodeVar*) malloc(sizeof(struct nodeVar));
	temp->next = stack;
	stack = temp;
}

void pushStackVal(int val)
{
	first = false;
	for (int i=0; i<STRINGLENGTH; i++)
	{
		stack->text[i] = '\0';
	}
	stack->val = val;
	struct nodeVar* temp = (struct nodeVar*) malloc(sizeof(struct nodeVar));
	temp->next = stack;
	stack = temp;
}

void popEntireStack()
{
	struct nodeVar* node = stack->next;
	stack->next = NULL;
	while (node != NULL)
	{
		if (strcmp("", node->text) == 0)
		{
			printf("%d ", node->val);
		}
		else
		{
			if (node->text[0] != '!')
				printf("%s ", node->text);
			else
				printf("%s", node->text);
		}
		struct nodeVar* temp = node;
		node = temp->next;
		temp->val = 0;
		for (int i=0; i<STRINGLENGTH; i++)
		{
			temp->text[i] = '\0';
		}
		free(temp);
	}
	printf("\n");
	first = true;
}

int main() {
	head = (struct nodeVar*) malloc(sizeof(struct nodeVar));
	stack = (struct nodeVar*) malloc(sizeof(struct nodeVar));
	first = true;
	stack->next = NULL;
	yyparse();
	freeNodes();
	return 0;
}
