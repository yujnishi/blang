O_RDONLY 0;
st[20];

main() {
    auto fd,fname "fstat.tmp";

    fd = creat(fname,292); /* 0444 */
    write(fd,"hello, world",12);
    close(fd);

    fd = open(fname,O_RDONLY);
    fstat(fd,st);
    printf("mode: %03o*n",st[2]);
    printf("size: %d*n",st[7]);
}


