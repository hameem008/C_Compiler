yacc -d -y 2005055.y
echo '2005055.y done'
g++ -w -c -o y.o y.tab.c
echo 'y.tab.c done'
flex 2005055.l
echo '2005055.l done'
g++ -w -c -o l.o lex.yy.c
echo 'lex.yy.c done'
g++ y.o l.o -lfl -o abc
echo 'abc done'
./abc in.txt
echo 'Bingo'