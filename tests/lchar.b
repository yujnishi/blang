src "hello, world";
dst "xxxxxxxxxxxxxxxxxxxx";

main() {
    auto c,i;

    printf("dst = '%s'*n",dst);
    i = 0;
    while ( (c=char(src,i)) != '*e' ) lchar(dst,i++,c);
    lchar(dst,i,'*e');
    printf("dst = '%s'*n",dst);
}

