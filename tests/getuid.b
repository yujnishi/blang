st[20];

main() {
    auto fd,fname "getuid.tmp",i;

    fd = creat(fname,384 /* 0600 */);
    fstat(fd,st);

    if ( st[4] == getuid() ) printf("it is mine*n");
    else                     printf("it is not mine*n");

    unlink(fname);
}
