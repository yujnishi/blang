NULL 0;

main() {
    auto fd,stdout,fname "dup.tmp";

    stdout = dup(1);

    fd = creat(fname,384);
    close(1);
    dup(fd);

    printf("Hello World.*n");
    close(1);
    close(fd);

    dup(stdout);
    if ( fork() == 0 ) execl("/bin/cat","cat",fname,NULL);
    wait();
}
