all: bb1 libb.so test

test: bb1
	gmake -C tests

b.tab.c: b.y
	bison -vtd $^

lex.yy.c: b.l b.tab.c
	lex -d -o $@ $<

bb1: b.tab.c lex.yy.c
	gcc -g -DYYDEBUG -DYYERROR_VERBOSE $^ -o $@

entry.s: libb.alias
	./mkentry.sh $^ > $@

libb.so: libb.c entry.s
	gcc -Wall -fPIC -fno-builtin -shared $^ -o $@ -ldl

%: %.b
	./bb1 $^ | llc - -o a.s
	gcc a.s -L. -lb

%.ll: %.c
	clang -S -g -emit-llvm $^

clean:
	rm -f bb1 b.tab.* lex.yy.c a.out core.* a.ll a.s b.output libb.so entry.s
	gmake -C tests clean

install: all
	mkdir -p /usr/libexec/blang
	cp bb1 /usr/libexec/blang
	cp libb.so /usr/lib
	cp blang /usr/bin

uninstall:
	rm /usr/bin/blang
	rm /usr/lib/libb.so
	rm /usr/libexec/blang/bb1
	rmdir /usr/libexec/blang
