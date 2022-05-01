bb3exp: bb3exp.tab.o lex.yy.o  
	g++ -o bb3exp lex.yy.o bb3exp.tab.o

lex.yy.o: bb3exp.l
	flex bb3exp.l; g++ -g -c lex.yy.c

bb3exp.tab.o: bb3exp.yy
	bison -d bb3exp.yy; g++ -g -c bb3exp.tab.cc

clean:
	rm -f p2 bb3exp.output *.o bb3exp.tab* lex.yy.c lex.yy.cc
