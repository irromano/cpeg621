cse3exp2: cse3exp2.tab.o lex.yy.o  
	g++ -o cse3exp2 lex.yy.o cse3exp2.tab.o

lex.yy.o: cse3exp2.l
	flex cse3exp2.l; g++ -g -c lex.yy.c

cse3exp2.tab.o: cse3exp2.yy
	bison -d cse3exp2.yy; g++ -g -c cse3exp2.tab.cc

clean:
	rm -f p2 cse3exp2.output *.o cse3exp2.tab* lex.yy.c lex.yy.cc
