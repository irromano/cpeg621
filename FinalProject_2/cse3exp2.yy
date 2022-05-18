%{

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <bits/stdc++.h>
#include <iostream>

#include "cse3exp2.tab.hh"

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
std::vector<std::vector<struct instNode*>> bbVector;
std::unordered_map<struct instNode*, std::unordered_set<struct instNode*>> adjDDG;
std::unordered_map<struct instNode*, struct instNode*> dependancies;
std::unordered_map<struct instNode*, std::unordered_set<struct instNode*>> duplicateMatrix;
int *tmpCnt;
int *bbCnt;
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
		struct instNode *next;
		struct instNode *prev;
		int bb;
		int parent;
		int split1;
		int split2;
		bool elseInst;
		int tabCnt;
		int startTime;
	} instNode;

	typedef struct varNode
	{
		char name[VARNAME_LEN];
		int val;
		int tmp;
		struct varNode *next;
		struct varNode *prev;
	} varNode;

	/* prototype functions */

	struct instNode* newInst(struct varNode *defVar, struct varNode *leftVar, struct varNode *rightVar, int varCnt, int operation, int val);
	struct varNode* assignVar(char* name, int val, int tmp);
	struct varNode* findVar(char* name, int val, int tmp);
	struct varNode* newVar(char* name, int val, int tmp);
	std::vector<struct instNode*> pushBBvector();
	void buildBBvector();
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
		(*bbCnt)++;
		$3->bb = *bbCnt;
		$$->split1 = *bbCnt;
		while(!(tmpVector.empty()))
		{
			struct instNode *tmpNode = tmpVector.back();
			tmpVector.pop_back();
			tmpNode->parent = $$->bb;
			tmpNode->tabCnt++;
			instVector.push_back(tmpNode);
		}
		struct instNode *node = newInst($$->defVar, $3->defVar, NULL, 2, '=', val);
		node->parent = $$->bb;
		node->tabCnt++;
		instVector.push_back(node);
		(*bbCnt)++;
		$$->split2 = *bbCnt;
		instVector.back()->split1 = *bbCnt +1;
		char zero[] = {'0', '\0'};
		struct varNode *zeroVar = findVar(zero, 0, 0);
		struct instNode *elseNode = newInst($$->defVar, zeroVar, NULL, 2, '=', 0);
		(*bbCnt)++;
		elseNode->split1 = *bbCnt;
		elseNode->parent = $$->bb;
		elseNode->elseInst = true;
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
		struct varNode *node = findVar(num, $1, 0);
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
		struct varNode *var = findVar(num, val, 0);
		instVector.push_back(newInst(NULL, var, NULL, 1, '=', val));
		$$ = instVector.back();
	}
	| TEXT '=' exp
	{
		char* str = $1;
		struct varNode *node = assignVar(str, $3->defVar->val, 0);
		if ($3->defVar->tmp && $3->bb == *bbCnt)
		{
			*tmpCnt = *tmpCnt - 1;
			instVector.back()->defVar = node;
			if (instVector.back()->parent)
			{
				instVector.rbegin()[1]->defVar = node;
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
	inst->next = NULL;
	inst->prev = NULL;
	inst->parent = 0;
	inst->split1 = 0;
	inst->split2 = 0;
	inst->elseInst = false;
	inst->startTime = 0;
	inst->bb = *bbCnt;
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
			return 3;
		case '=':
		case '?':
			return 2;
		case '*':
		case '/':
			return 6;
		case '^':
			return 10;
		default:
			break;
	}
	return 0;
}

std::vector<struct instNode*> pushBBvector()
{
	std::vector<struct instNode*> bb;
	bbVector.push_back(bb);
	return bb;
}

void buildBBvector()
{
	for (int i=0; i<*bbCnt; i++)
		pushBBvector();
	for (auto tmp = instVector.begin(); tmp != instVector.end(); ++tmp)
	{
		bbVector[(*tmp)->bb - 1].push_back(*tmp);
	}
}

int findStartTime(std::unordered_set<struct instNode*> set, int prevStartTime)
{
	int time = prevStartTime + 1;
	for (struct instNode *node : set)
	{
		int tmpLat = (latency(node->operation) + node->startTime);
		time = (tmpLat > time) ? tmpLat : time;
	}
	return time;
}

void loadMap()
{
	for (auto inst = adjDDG.begin(); inst != adjDDG.end(); inst++)
		adjDDG.erase(inst);
	for (auto inst = instVector.rbegin(); inst != instVector.rend(); inst++)
	{
		std::unordered_set<struct instNode*> tmpSet;
		auto maxStall =  (inst + latency((*inst)->operation) < instVector.rend()) ? inst + latency((*inst)->operation) : instVector.rend();
		for (auto otherInst = inst+1; otherInst < maxStall; ++otherInst)
		{
			if ((*otherInst)->defVar == (*inst)->defVar || (*otherInst)->defVar == (*inst)->leftVar || (*otherInst)->defVar == (*inst)->rightVar && ((*inst)->operation == '+' || (*inst)->operation == '*'))
			{
				tmpSet.insert(*otherInst);
				dependancies[*otherInst] = *inst;
			}
		}
		adjDDG[*inst] = tmpSet;
	}
}

void cseHelper(struct instNode *inst, struct varNode *var)
{
	inst->leftVar = var;
	inst->operation = '=';
}



void cse()
{
	for (auto common = duplicateMatrix.begin(); common != duplicateMatrix.end(); common++)
	{
		struct instNode *commonSub = newInst(NULL, (common->first)->leftVar, (common->first)->rightVar, (common->first)->varCnt, (common->first)->operation, (common->first)->defVar->val);
		auto inst = std::find(instVector.begin(), instVector.end(), common->first);
		commonSub->bb = (*inst)->bb;
		if (inst != instVector.end())
		{
			instVector.insert(inst, commonSub);
			cseHelper(common->first, commonSub->defVar);
			for (auto dup = (common->second).begin(); dup != (common->second).end(); dup++)
			{
				cseHelper((*dup), commonSub->defVar);
			}
		}
	}
}

void loadDuplicates()
{
	loadMap();
	std::unordered_set<struct instNode*> dupSet;	//Used to prevent cs created from an expression already eliminated
	for (auto inst = instVector.begin(); inst != instVector.end(); inst++)
	{
		if ((latency((*inst)->operation) != 2) && dependancies[*inst])		// If inst operation is +, -, *, /, or **
		{
			if (dupSet.find((*inst)) == dupSet.end())
			{
				std::unordered_set<struct instNode*> tmpSet;
				for (auto otherInst = inst + 1; otherInst != instVector.end(); otherInst++)
				{
					if ((*otherInst)->operation == (*inst)->operation)
					{
						if ((*otherInst)->parent == (*inst)->parent)
						{
							struct varNode *left = (*inst)->leftVar;
							struct varNode *right = (*inst)->rightVar;
							if ((*otherInst)->leftVar == left && (*otherInst)->rightVar == right || (*otherInst)->leftVar == right && (*otherInst)->rightVar == left)
							{
								bool modified = false;
								auto tmpInst = inst;
								while (tmpInst != otherInst)
								{
									if ((*tmpInst)->defVar == left || (*tmpInst)->defVar == right)
									{
										modified = true;
										break;
									}
									tmpInst++;
								}
								if (!modified)
								{
									tmpSet.insert(*otherInst);
									dupSet.insert(tmpSet.begin(), tmpSet.end());
								}
							}
						}
					}
				}
				if (tmpSet.size())	
				{
					duplicateMatrix[*inst] = tmpSet;
				}
			}
		}
	}
	cse();
}

int programLatency()
{
	instVector[0]->startTime = 0;
	int maxInstFinish = latency(instVector[0]->operation);
	instNode* lastInst = instVector[0];
	for (int i=1; i<instVector.size(); i++)
	{
		while (instVector[i]->elseInst)
			i++;
		instVector[i]->startTime = findStartTime(adjDDG[instVector[i]], lastInst->startTime);
		if (instVector[i]->startTime + latency(instVector[i]->operation) > maxInstFinish)
			maxInstFinish = instVector[i]->startTime + latency(instVector[i]->operation);
		lastInst = instVector[i];
	}

	return maxInstFinish;
}

void printStack()
{
	int bCnt = 1;
	for (auto bb = bbVector.begin(); bb != bbVector.end(); bb++)
	{
		if ((*bb).size() > 0)
			std::cout << "BB" << bCnt++ << ":" << std::endl;
		int lastTabCnt = 0;
		for (auto tmp = (*bb).begin(); tmp != (*bb).end(); tmp++)
		{
			std::cout << "\t";
			if ((*tmp)->tabCnt < lastTabCnt && (*tmp)->operation != '|')
				std::cout << "}\n\t";
			switch((*tmp)->operation) {
				case '=':
					std::cout << (*tmp)->defVar->name << "=" << (*tmp)->leftVar->name << ";" << std::endl;
					if ((*tmp)->split1)
						std::cout << "\tgoto BB" << (*tmp)->split1 << ";" << std::endl;
					break;
				case '+':
				case '-':
				case '*':
				case '/':
					std::cout << (*tmp)->defVar->name << "=" << (*tmp)->leftVar->name << (*tmp)->operation << (*tmp)->rightVar->name << ";" << std::endl;
					if ((*tmp)->split1)
						std::cout << "\tgoto BB" << (*tmp)->split1 << ";" << std::endl;
					break;
				case '^':
					std::cout << (*tmp)->defVar->name << "=" << (*tmp)->leftVar->name << "**" << (*tmp)->rightVar->name << ";" << std::endl;
					if ((*tmp)->split1)
						std::cout << "\tgoto BB;" << (*tmp)->split1 << ";" << std::endl;
					break;
				case '?':
					std::cout << "If(" << (*tmp)->leftVar->name << "){" << std::endl;
					std::cout << "\t\tgoto BB" << (*tmp)->split1 << ";" << std::endl;
					std::cout << "\t}else{" << std::endl;
					std::cout << "\t\tgoto BB" << (*tmp)->split2 << ";" << std::endl;
					std::cout << "\t}" << std::endl;
					break;
				default:
					break;
			}
			lastTabCnt = (*tmp)->tabCnt;
		}
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
	bbCnt = new int;
	*bbCnt = 1;
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
	loadDuplicates();
	buildBBvector();
	loadMap();
	int cycles = programLatency();
	printStack();
	std::cout << "Cycles required to run: " << cycles << std::endl;
	delete tmpCnt;
	delete bbCnt;
	fclose(yyin);
	return 0;
}
