# flex2
Implementing regular expressions 
Program written in C using flex. Makefile is provided by Dr. Dalio 
PROJS  = hmwk_02b
CC     = gcc
CFLAGS = -g -Wall -Wextra -fsanitize=address -fsanitize=leak -static-libasan

all : $(PROJS)

hmwk_02b : hmwk_02b.l
	flex hmwk_02b.l
	$(CC) $(CFLAGS) -o hmwk_02b lex.yy.c

clean:
	rm -f *.o $(PROJS) lex.yy.[ch] hmwk*.tab.[ch]


