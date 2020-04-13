printn(n, b) {
    extrn putchar;
    auto a;

    if (a = n / b)
        printn(a, b);
    putchar(n % b + '0');
}

_printf(fmt, x1,x2,x3,x4,x5,x6,x7,x8,x9) {
	extrn printn, char, putchar;
	auto adx, x, c, i, j;

	i= 0;	/* fmt index */
	adx = &x1;	/* argument pointer */
loop :
	while((c=char(fmt,i++) ) != '%') {
		if(c == '*e')
			return;
		putchar(c);
	}
    /**
     * TODO ポインタの場合はsizeof(void*)分だけ足すほうが自然？
     *      最初の代入で型が決まる言語かな
	 * x = *adx++;
     */
	x = *adx;
    adx =- 8; /* 最適化すると動かなくなる */
	switch c = char(fmt,i++) {

	case 'd': /* decimal */
	case 'o': /* octal */
		if(x < 0) {
			x = -x ;
			putchar('-');
		}
		printn(x, c=='o'?8:10);
		goto loop;

	case 'c' : /* char */
		putchar(x);
		goto loop;

	case 's': /* string */
		while((c=char(x, j++)) != '*e')
			putchar(c);
		goto loop;
	}
	putchar('%') ;
	i--;
	adx--;
	goto loop;
}

main() {
    _printf("Hello world. %d:%d*n",128,256,0,0,0,0,0,0,0);
}
