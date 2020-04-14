p[2];

main() {
    auto c;

    pipe(p);
    if ( fork() ) {
        close(1);
        dup(p[1]);

        printf("hello world*n");
    } else {
        close(0);
        dup(p[0]);

        while ( (c=getchar()) != '*n' ) printf("%c*n",c);
        printf("*n");
    }
    wait();
}
