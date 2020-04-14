st[20];

main() {
    auto fd,i;

    /* TODO ファイルが存在するとしっぱいするのでclean必要 */
    fd = creat("getuid.tmp",384 /* 0600 */);
    fstat(fd,st);

    if ( st[4] == getuid() ) printf("it is mine*n");
    else                     printf("it is not mine*n");
}
