%{

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <iostream>
#include <bits/stdc++.h>

#include "fe3exp.tab.hh"

//#define DEBUG /* for debuging: print production results */
int lineNum = 1;

void yyerror(char *ps, ...) 
{ /* need this to avoid link problem */
	printf("%s\n", ps);
}

extern FILE *yyin;
int yylex();

std::vector<struct varNode*> varVector;
std::vector<struct instNode*> instVector;
std::unordered_map<struct instNode*, std::unordered_set<struct instNode*>> adjDDG;
std::vector<struct instNode*> schedInstVector;
int *tmpCnt;
%}

%code requires {
#include <vector>
const int VARNAME_LEN = 100;
	typedef struct instNode
	{
		struct varNode *defVar;
		struct varNode *leftVar;
		struct varNode *rightVar;
		int varCnt;
		char operation;
		struct instNode *parent;
		int tabCnt;
		int startTime;
	} instNode;

	typedef struct varNode
	{
		char name[VARNAME_LEN];
		int val;
		int tmp;
	} varNode;

	/* prototype functions */

	struct instNode* newInst(struct varNode *defVar, struct varNode *leftVar, struct varNode *rightVar, int varCnt, int operation, int val);
	struct varNode* assignVar(char* name, int val, int tmp);
	struct varNode* findVar(char* name, int val, int tmp);
	struct varNode* newVar(char* name, int val, int tmp);
	
	int findStartTime(std::unordered_set<struct instNode*> set);
}

%union {
	char name[20];
	int d;
	struct instNode *nInst;
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
		instVector.push_back(newInst(NULL, $1->defVar, $3->defVar, 3, '+', val));
		$$ = instVector.back();
	}
	| exp '-' factor
	{ 
		int val = $1->defVar->val - $3->defVar->val;
		instVector.push_back(newInst(NULL, $1->defVar, $3->defVar, 3, '-', val));
		$$ = instVector.back();
	}
	| factor '?' term
	{
		int val = 0;
		if ($1->defVar->val != 0)
			val = $3->defVar->val;

		int instCnt = 0;
		std::vector<struct instNode*> tmpVector;
		while ($1 != instVector.back())
		{
			tmpVector.push_back(instVector.back());
			instVector.pop_back();
		}
		instVector.push_back(newInst(NULL, $1->defVar, $3->defVar, 3, '?', val));
		$$ = instVector.back();
		while(!(tmpVector.empty()))
		{
			struct instNode *tmpNode = tmpVector.back();
			tmpVector.pop_back();
			tmpNode->parent = $$;
			tmpNode->tabCnt++;
			instVector.push_back(tmpNode);
		}
		struct instNode *node = newInst($$->defVar, $3->defVar, NULL, 2, '=', val);
		node->parent = $$;
		node->tabCnt++;
		instVector.push_back(node);
		instVector.push_back(newInst($3->defVar, NULL, NULL, 0, '|', 0));
		struct varNode *zeroVar = findVar("0", 0, 0);
		struct instNode *elseNode = newInst($$->defVar, zeroVar, NULL, 2, '=', 0);
		elseNode->parent = $$;
		elseNode->tabCnt++;
		instVector.push_back(elseNode);
	}
    | factor
	{ 
		$$ = $1;
	};

factor : factor '*' term
	{ 
		int val = $1->defVar->val * $3->defVar->val; 
		instVector.push_back(newInst(NULL, $1->defVar, $3->defVar, 3, '*', val));
		$$ = instVector.back();
	}
	| factor '/' term
	{ 
		int val = $1->defVar->val / $3->defVar->val; 
		instVector.push_back(newInst(NULL, $1->defVar, $3->defVar, 3, '/', val));
		$$ = instVector.back();
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
		instVector.push_back(newInst(NULL, $1->defVar, $3->defVar, 3, '^', val));
		$$ = instVector.back();
	}

term : NUMBER
	{ 
		char num[VARNAME_LEN];
		sprintf(num, "%d", $1);
		struct varNode *node = newVar(num, $1, 0);
		varVector.push_back(node);
		$$ = newInst(varVector.back(), NULL, NULL, 1, '=', $1);
	}
     | '(' exp ')'
	{
		$$ = $2;
	}
	| TEXT
	{
		struct varNode *node = findVar($1, 0, 0);
		$$ = newInst(node, NULL, NULL, 1, '=', node->val);
	}
	| '!' term
	{
		int val = ($2->defVar->val == 0) ? 1 : 0;
		char num[VARNAME_LEN];
		sprintf(num, "%d", val);
		struct varNode *var = newVar(num, val, 0);
		instVector.push_back(newInst(NULL, var, NULL, 1, '=', val));
		$$ = instVector.back();
	}
	| TEXT '=' exp
	{
		char* str = $1;
		struct varNode *node = assignVar(str, $3->defVar->val, 0);
		if ($3->defVar->tmp)
		{
			*tmpCnt = *tmpCnt - 1;
			instVector.back()->defVar = node;
			if (instVector.back()->parent != NULL)
			{
				instVector.rbegin()[2]->defVar = node;
				*tmpCnt = *tmpCnt - 1;
			}
		}
		else
		{
			instVector.push_back(newInst(node, $3->defVar, NULL, 2, '=', node->val));
		}
		$$ = instVector.back();

	}
	| expone
	{
		$$ = $1;
	}
	;

%%

struct instNode* newInst(struct varNode *defVar, struct varNode *leftVar, struct varNode *rightVar, int varCnt, int operation, int val)
{
	struct instNode* inst = (struct instNode*) malloc(sizeof(struct instNode));
	if (defVar == NULL)
	{
		char tmp[VARNAME_LEN];
		sprintf(tmp, "tmp%d", *tmpCnt);
		*tmpCnt = *tmpCnt + 1;
		struct varNode *node = assignVar(tmp, val, 1);
		inst->defVar = node;
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
	inst->startTime = 0;
	inst->parent = NULL;
	return inst;
}

struct varNode* assignVar(char* name, int val, int tmp)
{
	struct varNode *var = findVar(name, val, tmp);
	var->val = val;
	return var;

}

struct varNode* findVar(char* name, int val, int tmp)
{
	for (auto var = varVector.begin(); var !=varVector.end(); ++var)
	{
		if(strcmp(name, (*var)->name) == 0)
		{
			return (*var);
		}
	}
	struct varNode *var = newVar(name, val, tmp);
	return varVector.back();
	
}

struct varNode* newVar(char* name, int val, int tmp)
{
	struct varNode *var = (struct varNode*) malloc(sizeof(struct varNode));
	sprintf(var->name, "%s", name);
	var->val = val;
	var->tmp = tmp;
	varVector.push_back(var);
	return var;
}

int latency(int op)
{
	switch (op)
	{
		case '+':
		case '-':
			return 1;
		case '=':
		case '?':
			return 2;
		case '*':
		case '/':
			return 4;
		case '^':
			return 8;
		default:
			break;
	}
	return 0;
}

int findStartTime(std::unordered_set<struct instNode*> set)
{
	if (set.empty())
	{
		return 0;
	}
	int time = 0;
	for (struct instNode *node : set)
	{
		int tmpLat = (latency(node->operation) + node->startTime);
		time = (tmpLat > time) ? tmpLat : time;
	}
	return time;
}

bool compareStartTime(struct instNode *node1, struct instNode *node2)
{
	return (node1->startTime < node2->startTime);
}

void loadMap()
{
	for (auto inst = instVector.rbegin(); inst != instVector.rend(); ++inst)
	{
		std::unordered_set<struct instNode*> tmpSet;
		for (auto otherInst = inst+1; otherInst != instVector.rend(); ++otherInst)
		{
			if ((*otherInst)->defVar == (*inst)->defVar || (*otherInst)->defVar == (*inst)->leftVar || (*otherInst)->defVar == (*inst)->rightVar)
			{
				tmpSet.insert(*otherInst);
			}
			else if ((*inst)->defVar == (*otherInst)->defVar || (*inst)->defVar == (*otherInst)->leftVar || (*inst)->defVar == (*otherInst)->rightVar)
			{
				tmpSet.insert(*otherInst);
			}
		}
		adjDDG[*inst] = tmpSet;
	}

	for (struct instNode *node : instVector)
	{
		node->startTime = findStartTime(adjDDG[node]);
	}
}

void schedInst()
{
	std::sort(instVector.begin(), instVector.end(), compareStartTime);
}

void printStack()
{
	int lastTabCnt = 0;
	for (auto tmp = instVector.begin(); tmp != instVector.end(); ++tmp)
	{
		for (int i=0; i<(*tmp)->tabCnt; i++)
			std::cout << "\t";
		if ((*tmp)->tabCnt < lastTabCnt && (*tmp)->operation != '|')
			std::cout << "}\n";
		switch((*tmp)->operation) {
			case '=':
				std::cout << (*tmp)->defVar->name << "=" << (*tmp)->leftVar->name << ";" << std::endl;
				break;
			case '+':
			case '-':
			case '*':
			case '/':
				std::cout << (*tmp)->defVar->name << "=" << (*tmp)->leftVar->name << (*tmp)->operation << (*tmp)->rightVar->name << ";" << std::endl;
				break;
			case '^':
				std::cout << (*tmp)->defVar->name << "=" << (*tmp)->leftVar->name << "**" << (*tmp)->rightVar->name << ";" << std::endl;
				break;
			case '?':
				std::cout << "If(" << (*tmp)->leftVar->name << "){" << std::endl;
				break;
			case '|':
				std::cout << "}else{" << std::endl;
			defautlt:
				break;
		}
		lastTabCnt = (*tmp)->tabCnt;
	}
}

void freeNodes()
{
	#ifdef DEBUG
	printf("Freeing all variable Nodes\n");
	#endif
	return;
}

int main(int argc, char *argv[]) {
	tmpCnt = new int;
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
	loadMap();
	schedInst();
	printStack();
	free(tmpCnt);
	fclose(yyin);
	return 0;
}
