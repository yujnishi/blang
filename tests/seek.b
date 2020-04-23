O_RDONLY 0;
O_WRONLY 1;
O_RDWR   2;

SEEK_SET 0;
SEEK_CUR 1;
SEEK_END 2;


main() {
    auto fd,buf "                                                ";

    fd = open("seek.b",O_RDONLY);
    seek(fd,-24,SEEK_END);
    read(fd,buf,24);
    write(1,buf,24);
    close(fd);
}
/* this is seek test */
