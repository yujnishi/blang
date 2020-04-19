O_RDONLY 0;
O_WRONLY 1;
O_RDWR   2;

main() {
    auto fd,c;

    fd = open("open.b",O_RDONLY);
    close(0);
    dup(fd);

    while ( (c=getchar()) != '*e' ) putchar(c);

    close(fd);
}
