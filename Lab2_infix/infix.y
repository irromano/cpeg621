%{
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>

//#define DEBUG /* for debuging: print production results */
int lineNum = 1;

/* prototype functions */
struct nodeVar* stackVar(char *name, int val, struct nodeVar *stackHead);
struct nodeVar* assignVar(char *name, int val);
struct nodeVar* findVar(char *name, int val, struct nodeVar *var);
struct nodeVar* newVar(char* name, int val);
void yyerror(char *ps, ...) 
{ /* need this to avoid link problem */
	printf("%s\n", ps);
}

extern FILE *yyin;

struct nodeVar *usrHead;
struct nodeVar *tmpHead;

int *tmpCnt;

%}

%code requires {
	struct nodeVar
	{
		char varName[100];
		int val;
		struct nodeVar *next;
	} nodeVar;
}

%union {
	char name[20];
	int d;
	struct nodeVar *nPtr;
}

// need to choose token type from union above
%token <d> NUMBER
%token <name> TEXT
%right '=' '?'
%token '(' ')'
%left '+' '-'
%left '*' '/'
%right POW
%right '!'
%type <nPtr> exp factor expone term
%right '\n'
%start infix

%%
infix : exp '\n'
	{ 
		//printf("=%d\n", $1->val);
	}
	| infix exp '\n'
	{ 
		//printf("=%d\n", $2->val);
	}
	| infix '\n'
	{
		#ifdef DEBUG
		printf("Blank '\\n' found\n");
		#endif
	}
	| '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	}
	| infix '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	}
	| '!' '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	}
	| infix '!' '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	};

exp : exp '+' factor
	{ 
		int val = $1->val + $3->val;
		$$ = stackVar("tmp", val, tmpHead);
		sprintf($$->varName, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		printf("%s=%s+%s;\n", $$->varName, $1->varName, $3->varName);
	}
	| exp '-' factor
	{ 
		int val = $1->val - $3->val;
		$$ = stackVar("tmp", val, tmpHead);
		sprintf($$->varName, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		printf("%s=%s-%s;\n", $$->varName, $1->varName, $3->varName);
	}
	| factor '?' term
	{
		if ($1->val == 0)
			$1->val = 0;
		else
			$1->val = $3->val;
		$$ = $1;
	}
    | factor
	{ 
		$$ = $1;
	};

factor : factor '*' term
	{ 
		int val = $1->val * $3->val; 
		$$ = stackVar("tmp", val, tmpHead);
		sprintf($$->varName, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		printf("%s=%s*%s;\n", $$->varName, $1->varName, $3->varName);
	}
	| factor '/' term
	{ 
		int val = $1->val / $3->val; 
		$$ = stackVar("tmp", val, tmpHead);
		sprintf($$->varName, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		printf("%s=%s/%s;\n", $$->varName, $1->varName, $3->varName);
	}
       | term
	{
		$$ = $1;
	}
	;
expone : term POW term
	{
		printf("%s=%s**%s;\n", $1->varName, $1->varName, $3->varName);
		int num = 1;
		for (int i=0; i<$3->val; i++)
		{
			num *= $1->val;
		}
		$1->val = num;
		$$ = $1;
	}

term : NUMBER
	{ 
		$$ = stackVar("tmp", $1, tmpHead);
		sprintf($$->varName, "%d", $1);
	}
     | '(' exp ')'
	{
		$$ = $2;
	}
	| TEXT
	{
		struct nodeVar *node = findVar($1, 0, usrHead);
		$$ = stackVar(node->varName, node->val, tmpHead);
	}
	| '!' term
	{
		int val = ($2->val == 0) ? 1 : 0;
		$$ = stackVar("tmp", val, tmpHead);
	}
	
	| TEXT '=' exp
	{
		struct nodeVar *node = assignVar($1, $3->val);
		$$ = stackVar(node->varName, node->val, tmpHead);
		printf("%s=%s;\n", $$->varName, $3->varName);
	}
	| expone
	{
		$$ = $1;
	}
	;

%%
struct nodeVar* stackVar(char *name, int val, struct nodeVar *stackHead)
{
	struct nodeVar *var = newVar(name, val);
	if (stackHead != NULL)
		var->next = tmpHead;
	stackHead = var;
	return var;
}


struct nodeVar* assignVar(char *name, int val)
{
	struct nodeVar *var = findVar(name, val, usrHead);
	var->val = val;
	return var;
}

struct nodeVar* findVar(char *name, int val, struct nodeVar *var)
{
	if(strcmp(name, var->varName) == 0)
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
	sscanf(name, "%s", var->varName);
	var->val = val;
	var->next = NULL;
	return var;
}

void freeNodes()
{
	#ifdef DEBUG
	printf("Freeing all variable Nodes\n");
	#endif
	struct nodeVar *node = usrHead->next;
	while(node != NULL)
	{
		struct nodeVar *tmp = node->next;
		free(node);
		node = tmp;
	}
	while(tmpHead != NULL)
	{
		struct nodeVar *tmp = tmpHead->next;
		free(tmpHead);
		tmpHead = tmp;
	}

	return;
}

int main(int argc, char *argv[]) {
	usrHead = (struct nodeVar*) malloc(sizeof(struct nodeVar));
	tmpHead = (struct nodeVar*) malloc(sizeof(struct nodeVar));
	tmpCnt = (int*) malloc(sizeof(int));
	*tmpCnt = 1;
	if (argc > 1)
	{
		yyin = fopen(argv[1], "r");
		if (yyin == NULL)
		{
			printf("ERROR: File input cannot be opened.\n");
			return 1;
		}
	}
	yyparse();
	freeNodes();
	free(tmpCnt);
	fclose(yyin);
	return 0;
}
