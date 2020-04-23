#!/bin/sh

for id in `cat $1`
do
    a=${id%%:*}
    n=${id##*:}
    echo "  .globl $a"
    echo "  .type  $a, @function"
    echo "$a:"
    echo "  jmp $n"
    echo "  .size  $a, .-$a"
    echo
done

