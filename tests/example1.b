printn(n, b) {
        extrn putchar;
        auto a;

        if (a = n / b)
                printn(a, b);
        putchar(n % b + '0');
}

main() {
    extrn putchar;
    auto i,j;

    j = 2;
    while ( j <= 10 ) {
        i = 0;
        while ( i <= 256 ) {
            printn(i,10);
            putchar('[');
            printn(j,10);
            putchar(']: ');
            printn(i,j);
            putchar('*n');
            i++;
        }
        j++;
    }

    return(0);
}
