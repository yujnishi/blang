/* this is read test */
O_RDONLY 0;
O_WRONLY 1;
O_RDWR   2;

main() {
    auto fd,buf "                                                ";

    fd = open("read.b",O_RDONLY);
    read(fd,buf,24);
    write(1,buf,24);
    close(fd);
}
