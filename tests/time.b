st[20];
tm1[2];
tm2[2];

main() {
    auto fd;

    time(tm1);

    fd = creat("time.tmp",384);
    fstat(fd,st);
    close(fd);

    time(tm2);

    if ( st[12] > tm1[0] & st[12] < tm2[0] ) printf("time func ok*n");
    else                                     printf("time func ng*n");
}
