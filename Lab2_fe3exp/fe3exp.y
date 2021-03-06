%{

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>

//#define DEBUG /* for debuging: print production results */
int lineNum = 1;

/* prototype functions */
struct nodeVar* stackPushNode(struct nodeVar* node);
struct nodeVar* stackPush(char* name, int val);
struct nodeVar* stackPop();
struct nodeVar* assignVar(char *name, int val);
struct nodeVar* findVar(char *name, int val, struct nodeVar *var);
struct nodeVar* newVar(char* name, int val);
void printStack();
void yyerror(char *ps, ...) 
{ /* need this to avoid link problem */
	printf("%s\n", ps);
}

extern FILE *yyin;

struct nodeVar *usrHead;
struct nodeStack *codeStack;

int *tmpCnt;

%}

%code requires {
#define VARNAME_LEN 100
#define VAREXP_LEN 500
	struct nodeVar
	{
		char name[VARNAME_LEN];
		int val;
		char exp[VAREXP_LEN];
		struct nodeVar *next;
		struct nodeVar *prev;
		int tabCnt;
		int conditional;
	} nodeVar;

	struct nodeStack
	{
		struct nodeVar *top;
		struct nodeVar *bottom;
		int cnt;
	} nodeStack;
}

%union {
	char name[20];
	int d;
	struct nodeVar *nPtr;
	struct nodeStack nStck;
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
%start fe3exp

%%
fe3exp : exp '\n'
	{ 
	}
	| fe3exp exp '\n'
	{ 
	}
	| fe3exp '\n'
	{
	}
	| '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	}
	| fe3exp '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	}
	| '!' '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	}
	| fe3exp '!' '(' exp '\n'
	{
		printf("Missing ')' closing parenthesis\n");
	};

exp : exp '+' factor
	{ 
		int val = $1->val + $3->val;
		$$ = stackPush("tmp", val);
		sprintf($$->name, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		sprintf($$->exp, "=%s+%s;\n", $1->name, $3->name);
	}
	| exp '-' factor
	{ 
		int val = $1->val - $3->val;
		$$ = stackPush("tmp", val);
		sprintf($$->name, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		sprintf($$->exp, "=%s-%s;\n", $1->name, $3->name);
	}
	| factor '?' term
	{
		int val = 0;
		if ($1->val != 0)
			val = $3->val;

		struct nodeVar *dependTop = NULL;
		struct nodeVar *dependBottom = NULL;
		int dependCnt = 0;
		while ($1 != codeStack->top)
		{
			dependCnt++;
			struct nodeVar *node = stackPop();
			if (dependTop == NULL)
			{
				dependTop = node;
			}
			node->tabCnt++;
			dependBottom = node;
		}
		dependBottom->prev = NULL;
		$$ = stackPush("tmp", val);
		sprintf($$->name, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		sprintf($$->exp, "If(%s){\n", $1->name);
		$$->conditional = 1;
		while(dependCnt)
		{
			stackPushNode(dependBottom);
			dependBottom = dependBottom->next;
			dependCnt--;
		}
		struct nodeVar *node = stackPush($$->name, $3->val);
		sprintf(node->exp, "=%s;\n}else{\n", node->prev->name);
		node->tabCnt++;
		struct nodeVar *elseNode = stackPush($$->name, 0);
		sprintf(elseNode->exp, "=0;\n}\n");
		elseNode->tabCnt++;
	}
    | factor
	{ 
		$$ = $1;
	};

factor : factor '*' term
	{ 
		int val = $1->val * $3->val; 
		$$ = stackPush("tmp", val);
		sprintf($$->name, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		sprintf($$->exp, "=%s*%s;\n", $1->name, $3->name);
	}
	| factor '/' term
	{ 
		int val = $1->val / $3->val; 
		$$ = stackPush("tmp", val);
		sprintf($$->name, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		sprintf($$->exp, "=%s/%s;\n", $1->name, $3->name);
	}
       | term
	{
		$$ = $1;
	}
	;
expone : term POW term
	{
		int val = 1;
		for (int i=0; i<$3->val; i++)
		{
			val *= $1->val;
		}
		$$ = stackPush("tmp", val);
		sprintf($$->name, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		sprintf($$->exp, "=%s**%s;\n", $1->name, $3->name);
	}

term : NUMBER
	{ 
		$$ = newVar("tmp", $1);
		sprintf($$->name, "%d", $1);
	}
     | '(' exp ')'
	{
		$$ = $2;
	}
	| TEXT
	{
		struct nodeVar *node = findVar($1, 0, usrHead);
		$$ = newVar(node->name, node->val);
	}
	| '!' term
	{
		int val = ($2->val == 0) ? 1 : 0;
		$$ = stackPush("tmp", val);
		sprintf($$->name, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		sprintf($$->exp, "=%d;\n", val);

	}
	
	| TEXT '=' exp
	{
		struct nodeVar *node = assignVar($1, $3->val);
		$$ = stackPush(node->name, node->val);
		sprintf($$->exp, "=%s;\n",$3->name);
	}
	| expone
	{
		$$ = $1;
	}
	;

%%

struct nodeVar* stackPushNode(struct nodeVar *node)
{
	if (codeStack->cnt)
		codeStack->top->next = node;
	else
		codeStack->bottom = node;
	node->prev = codeStack->top;
	codeStack->top = node;
	codeStack->cnt++;
	return codeStack->top;
}

struct nodeVar* stackPush(char* name, int val)
{
	struct nodeVar *node = newVar(name, val);
	return stackPushNode(node);
}

struct nodeVar* stackPop()
{
	struct nodeVar *node = codeStack->top;
	codeStack->top = codeStack->top->prev;
	//codeStack->top->next = NULL;
	codeStack->cnt--;
	return node;
}


struct nodeVar* assignVar(char *name, int val)
{
	struct nodeVar *var = findVar(name, val, usrHead);
	var->val = val;
	return var;

}

struct nodeVar* findVar(char *name, int val, struct nodeVar *var)
{
	if(strcmp(name, var->name) == 0)
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
	sprintf(var->name, "%s", name);
	var->val = val;
	var->next = NULL;
	var->tabCnt = 0;
	var->conditional = 0;
	return var;
}

void printStack()
{
	struct nodeVar * tmp = codeStack->bottom;
	while (tmp != NULL)
	{
		for (int i=0; i<tmp->tabCnt; i++)
			printf("\t");
		if (tmp->conditional)
			printf("%s", tmp->exp);
		else
			printf("%s%s", tmp->name, tmp->exp);
		struct nodeVar *next = tmp->next;
		free(tmp);
		tmp = next;
	}
	codeStack->bottom = NULL;
	codeStack->top = NULL;
	codeStack->cnt = 0;
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
	while(codeStack->bottom != NULL)
	{
		struct nodeVar *tmp = codeStack->bottom->next;
		free(codeStack->bottom);
		codeStack->bottom = tmp;
	}
	free(codeStack);

	return;
}

int main(int argc, char *argv[]) {
	usrHead = (struct nodeVar*) malloc(sizeof(struct nodeVar));
	codeStack = (struct nodeStack*) malloc(sizeof(struct nodeStack));
	codeStack->top = NULL;
	codeStack->bottom = NULL;
	codeStack->cnt = 0;
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
	printStack();
	freeNodes();
	free(tmpCnt);
	fclose(yyin);
	return 0;
}
