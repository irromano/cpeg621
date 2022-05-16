cse3exp: cse3exp.tab.o lex.yy.o  
	g++ -o cse3exp lex.yy.o cse3exp.tab.o

lex.yy.o: cse3exp.l
	flex cse3exp.l; g++ -g -c lex.yy.c

cse3exp.tab.o: cse3exp.yy
	bison -d cse3exp.yy; g++ -g -c cse3exp.tab.cc

clean:
	rm -f p2 cse3exp.output *.o cse3exp.tab* lex.yy.c lex.yy.cc
