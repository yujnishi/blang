.PHONY: tests build
.PRECIOUS: %.ll

srcs  = $(wildcard *.b)
objs  = $(patsubst %.b,%,$(srcs))
cases = $(patsubst %.b,%.diff,$(srcs))

tests: build $(cases)


build: $(objs)

%.diff: %.res
	diff `basename $^ .res`.out $^ > $@

%.res: %
	LANG=C LD_LIBRARY_PATH=.. ./$< > $@

%: %.s
	gcc $^ -L.. -lb -o $@

%.s: %.ll
	llc $^ -O0 -o $@

%.ll: %.b ../bb1
	../bb1 $< > $@

clean:
	rm -fr $(cases) $(objs) *.ll *.s *.res *.tmp core.*
