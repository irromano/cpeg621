cc3exp: cc3exp.tab.o lex.yy.o  
	g++ -o cc3exp lex.yy.o cc3exp.tab.o

lex.yy.o: cc3exp.l
	flex cc3exp.l; g++ -g -c lex.yy.c

cc3exp.tab.o: cc3exp.yy
	bison -d cc3exp.yy; g++ -g -c cc3exp.tab.cc

clean:
	rm -f p2 cc3exp.output *.o cc3exp.tab* lex.yy.c lex.yy.cc
