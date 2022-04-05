fe3exp: fe3exp.tab.o lex.yy.o  
	gcc -o fe3exp lex.yy.o fe3exp.tab.o

lex.yy.o: fe3exp.l
	flex fe3exp.l; gcc -c lex.yy.c

fe3exp.tab.o: fe3exp.y
	bison -d fe3exp.y; gcc -c fe3exp.tab.c

clean:
	rm -f p2 fe3exp.output *.o fe3exp.tab* lex.yy.c
