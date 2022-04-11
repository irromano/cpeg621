fe3exp: fe3exp.tab.o lex.yy.o  
	g++ -o fe3exp lex.yy.o fe3exp.tab.o

lex.yy.o: fe3exp.l
	flex fe3exp.l; g++ -g -c lex.yy.c

fe3exp.tab.o: fe3exp.yy
	bison -d fe3exp.yy; g++ -g -c fe3exp.tab.cc

clean:
	rm -f p2 fe3exp.output *.o fe3exp.tab* lex.yy.c lex.yy.cc
