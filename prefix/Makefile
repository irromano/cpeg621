prefix: prefix.tab.o lex.yy.o  
	gcc -o prefix lex.yy.o prefix.tab.o

lex.yy.o: prefix.l
	flex prefix.l; gcc -c lex.yy.c

prefix.tab.o: prefix.y
	bison -d prefix.y; gcc -c prefix.tab.c

clean:
	rm -f p2 prefix.output *.o prefix.tab* lex.yy.c
