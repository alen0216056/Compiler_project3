all:
	yacc -d -v parser.y
	flex lex.l
	cc -c lex.yy.c -o lex.yy.o
	g++ -std=c++11 lex.yy.o y.tab.c -o parser
