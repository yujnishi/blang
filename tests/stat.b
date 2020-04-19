O_RDONLY 0;
st[20];

main() {
    auto fd,fname "stat.tmp";

    fd = creat(fname,292); /* 0444 */
    write(fd,"hello, world",12);
    close(fd);

    stat(fname,st);
    printf("mode: %03o*n",st[2]);
    printf("size: %d*n",st[7]);
}


