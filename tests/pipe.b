p[2];

main() {
    auto buf "                    ";

    pipe(p);
    write(p[1],"hello, world*n",13);
    read(p[0],buf,13);
    write(1,buf,13);
    close(p[0]);
    close(p[1]);
}
