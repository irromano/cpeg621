%{

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>

//#define DEBUG /* for debuging: print production results */
int lineNum = 1;

void yyerror(char *ps, ...) 
{ /* need this to avoid link problem */
	printf("%s\n", ps);
}

extern FILE *yyin;

%}

%code requires {
#define VARNAME_LEN 100

	typedef struct instNode
	{
		struct varNode *defVar;
		struct varNode *leftVar;
		struct varNode *rightVar;
		int varCnt;
		int operation;
		struct instNode *next;
		struct instNode *prev;
		struct instNode *parent;
		int tabCnt;
	} instNode;

	typedef struct varNode
	{
		char name[VARNAME_LEN];
		int val;
		int tmp;
		struct varNode *next;
		struct varNode *prev;
	} varNode;

	typedef struct dependNode
	{
		struct instNode *inst;
		struct dependNode *depend1;
		struct dependNode *depend2;
		struct dependNode *depend3;
		int weight1;
		int weight2;
		int weight3;
		int dependCnt;
		struct dependNode *next;
		struct dependNode *prev;
	} dependNode;

	typedef struct instStack
	{
		struct instNode *top;
		struct instNode *bottom;
		int cnt;
	} instStack;

	typedef struct literalStack
	{
		struct varNode *top;
	} literalStack;

	typedef struct dependStack
	{
		struct dependNode *bottom;
		struct dependNode *top;
	} dependStack;

	/* prototype functions */
	struct instNode* stackPushNode(struct instNode *node);
	struct instNode* stackPush(struct varNode *defVar, struct varNode *leftVar, struct varNode *rightVar, int varCnt, int operation, int val);
	struct instNode* stackPop();
	struct varNode* literalPush(int d);
	struct varNode* literalPop();
	struct instNode* newInst(struct varNode *defVar, struct varNode *leftVar, struct varNode *rightVar, int varCnt, int operation, int val);
	struct varNode* assignVar(char *name, int val, int tmp);
	struct varNode* findVar(char *name, int val, struct varNode *var, int tmp);
	struct varNode* newVar(char* name, int val, int tmp);
	struct dependNode* newDepend(struct instNode *inst);
	struct dependNode* pushDepend(struct instNode *inst);
	void printStack();

	struct varNode *usrHead;
	struct instStack *codeStack;
	struct literalStack *literals;
	struct dependStack *DDG;

	int *tmpCnt;
}

%union {
	char name[20];
	int d;
	struct instNode *nInst;
	struct instStack nStck;
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
%type <nInst> exp factor expone term
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
		int val = $1->defVar->val + $3->defVar->val;
		$$ = stackPush(NULL, $1->defVar, $3->defVar, 3, '+', val);
	}
	| exp '-' factor
	{ 
		int val = $1->defVar->val - $3->defVar->val;
		$$ = stackPush(NULL, $1->defVar, $3->defVar, 3, '-', val);
	}
	| factor '?' term
	{
		int val = 0;
		if ($1->defVar->val != 0)
			val = $3->defVar->val;

		struct instNode *dependTop = NULL;
		struct instNode *dependBottom = NULL;
		int instCnt = 0;
		while ($1 != codeStack->top)
		{
			instCnt++;
			struct instNode *node = stackPop();
			if (dependTop == NULL)
			{
				dependTop = node;
			}
			node->tabCnt++;
			dependBottom = node;
		}
		if (instCnt)
			dependBottom->prev = NULL;
		$$ = stackPush(NULL, $1->defVar, $3->defVar, 3, '?', val);
		while(instCnt)
		{
			dependBottom->parent = $$;
			stackPushNode(dependBottom);
			dependBottom = dependBottom->next;
			instCnt--;
		}
		struct instNode *node = stackPush($$->defVar, $3->defVar, NULL, 2, '=', val);
		node->parent = $$;
		node->tabCnt++;
		stackPush(NULL, NULL, NULL, 0, '|', 0);
		struct varNode *lit = literalPush(0);
		struct instNode *elseNode = stackPush($$->defVar, lit, NULL, 2, '=', 0);
		elseNode->parent = $$;
		elseNode->tabCnt++;
	}
    | factor
	{ 
		$$ = $1;
	};

factor : factor '*' term
	{ 
		int val = $1->defVar->val * $3->defVar->val; 
		$$ = stackPush(NULL, $1->defVar, $3->defVar, 3, '*', val);
	}
	| factor '/' term
	{ 
		int val = $1->defVar->val / $3->defVar->val; 
		$$ = stackPush(NULL, $1->defVar, $3->defVar, 3, '/', val);
	}
       | term
	{
		$$ = $1;
	}
	;
expone : term POW term
	{
		int val = 1;
		for (int i=0; i<$3->defVar->val; i++)
		{
			val *= $1->defVar->val;
		}
		$$ = stackPush(NULL, $1->defVar, $3->defVar, 3, '^', val);
	}

term : NUMBER
	{ 
		struct varNode *lit = literalPush($1);
		$$ = newInst(lit, NULL, NULL, 1, '=', $1);
	}
     | '(' exp ')'
	{
		$$ = $2;
	}
	| TEXT
	{
		struct varNode *node = findVar($1, 0, usrHead, 0);
		$$ = newInst(node,NULL, NULL, 1, '=', node->val);
	}
	| '!' term
	{
		int val = ($2->defVar->val == 0) ? 1 : 0;
		struct varNode *lit = literalPush(val);
		if (codeStack->cnt && codeStack->top->defVar->tmp)
		{
			struct instNode *top = stackPop();
		}
		$$ = stackPush(NULL, lit, NULL, 1, '=', val);
	}
	| TEXT '=' exp
	{
		struct varNode *node = assignVar($1, $3->defVar->val, 0);
		struct varNode *tmpNode = $3->defVar;
		if (codeStack->cnt && codeStack->top->defVar->tmp && tmpNode == codeStack->top->defVar)
		{
			codeStack->top->defVar = node;
			*tmpCnt = *tmpCnt - 1;
			$$ = $3;
			if (codeStack->top->parent != NULL)
			{
				codeStack->top->prev->prev->defVar = node;
			}
		}
		else
		{
			$$ = stackPush(node, $3->defVar, NULL, 2, '=', node->val);
		}
	}
	| expone
	{
		$$ = $1;
	}
	;

%%

struct instNode* stackPushNode(struct instNode *node)
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
struct instNode* stackPush(struct varNode *defVar, struct varNode *leftVar, struct varNode *rightVar, int varCnt, int operation, int val)
{
	struct instNode *node = newInst(defVar, leftVar,  rightVar, varCnt, operation, val);
	return stackPushNode(node);
}

struct instNode* stackPop()
{
	struct instNode *node = codeStack->top;
	codeStack->top = codeStack->top->prev;
	//codeStack->top->next = NULL;
	codeStack->cnt--;
	return node;
}

struct varNode* literalPush(int d)
{
	struct varNode *node = newVar("L", d, 1);
	sprintf(node->name, "%d", d);
	if (literals->top == NULL)
	{
		literals->top = node;
	}
	else
	{
		literals->top->next = node;
		node->prev = literals->top;
		literals->top = node;
	}
	return node;
}
struct varNode* literalPop()
{
	struct varNode *next = literals->top;
	literals->top = next->prev;
	return next;
}

struct instNode* newInst(struct varNode *defVar, struct varNode *leftVar, struct varNode *rightVar, int varCnt, int operation, int val)
{
	struct instNode* inst = (struct instNode*) malloc(sizeof(struct instNode));
	if (defVar == NULL)
	{
		char tmp[VARNAME_LEN];
		sprintf(tmp, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		inst->defVar = assignVar(tmp, val, 1);
	}
	else
	{
		inst->defVar = defVar;
	}
	inst->leftVar = leftVar;
	if (rightVar != NULL)
	{
		inst->rightVar = rightVar;
	}
	inst->varCnt = varCnt;
	inst->operation = operation;
	inst->tabCnt = 0;
	inst->next = NULL;
	inst->prev = NULL;
	inst->parent = NULL;
	return inst;
}

struct varNode* assignVar(char *name, int val, int tmp)
{
	struct varNode *var = findVar(name, val, usrHead, tmp);
	var->val = val;
	return var;

}

struct varNode* findVar(char *name, int val, struct varNode *var, int tmp)
{
	if(strcmp(name, var->name) == 0)
	{
		return var;
	}
	else if (var->next == NULL)
	{
		var->next = newVar(name, val, tmp);
		return var->next;
	}
	else
	{
		return findVar(name, val, var->next, tmp);
	}
	
}

struct varNode* newVar(char* name, int val, int tmp)
{
	struct varNode *var = (struct varNode*) malloc(sizeof(struct varNode));
	sprintf(var->name, "%s", name);
	var->val = val;
	var->tmp = tmp;
	var->next = NULL;
	return var;
}

struct dependNode* newDepend(struct instNode *inst)
{
	struct dependNode *depend = (struct dependNode*) malloc(sizeof(struct dependNode));
	depend->inst = inst;
	depend->dependCnt = 0;
	depend->next = NULL;
	depend->prev = NULL;
	return depend;
}

struct dependNode* pushDepend(struct instNode *inst)
{
	struct dependNode *depend = newDepend(inst);
	if (DDG->bottom == NULL)
	{
		DDG->bottom = depend;
	}
	else
	{
		DDG->top->next = depend;
		depend->prev = DDG->top;
	}
	DDG->top = depend;
	return depend;
}

void loadDepend()
{
	struct instNode *inst = codeStack->bottom;
	while (inst != NULL)
	{
		pushDepend(inst);
		inst = inst->next;
	}
}

void printStack()
{
	struct instNode *tmp = codeStack->bottom;
	int lastTabCnt = 0;
	while (tmp != NULL)
	{
		for (int i=0; i<tmp->tabCnt; i++)
			printf("\t");
		if (tmp->tabCnt < lastTabCnt && tmp->operation != '|')
			printf("}\n");
		switch(tmp->operation) {
			case '=':
				printf("%s=%s;\n", tmp->defVar->name, tmp->leftVar->name);
				break;
			case '+':
			case '-':
			case '*':
			case '/':
				printf("%s=%s%c%s;\n", tmp->defVar->name, tmp->leftVar->name, tmp->operation, tmp->rightVar->name);
				break;
			case '^':
				printf("%s=%s**%s;\n", tmp->defVar->name, tmp->leftVar->name, tmp->rightVar->name);
				break;
			case '?':
				printf("If(%s){\n", tmp->leftVar->name);
				break;
			case '|':
				printf("}else{\n");
			defautlt:
				break;
		}
		lastTabCnt = tmp->tabCnt;
		struct instNode *next = tmp->next;
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
	struct varNode *node = usrHead->next;
	while(node != NULL)
	{
		struct varNode *tmp = node->next;
		free(node);
		node = tmp;
	}
	while(codeStack->bottom != NULL)
	{
		struct instNode *tmp = codeStack->bottom->next;
		free(codeStack->bottom);
		codeStack->bottom = tmp;
	}
	free(codeStack);
	while(literals->top != NULL)
	{
		struct varNode *tmp = literals->top->prev;
		free(literals->top);
		literals->top = tmp;
	}
	free(literals);

	return;
}

void printDDG()
{
	struct dependNode* node = DDG->bottom;
	while (node != NULL)
	{
		if (node->inst->defVar != NULL)
			printf("%s\n", node->inst->defVar->name);
		else
			printf("No defVar\n");
		node = node->next;
	}
}

int main(int argc, char *argv[]) {
	usrHead = (struct varNode*) malloc(sizeof(struct varNode));
	codeStack = (struct instStack*) malloc(sizeof(struct instStack));
	literals = (struct literalStack*) malloc(sizeof(struct literalStack));
	DDG = (struct dependStack*) malloc(sizeof(struct dependStack));
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
	loadDepend();
	printDDG();
	printStack();
	freeNodes();
	free(tmpCnt);
	fclose(yyin);
	return 0;
}
