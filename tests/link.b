NULL 0;

main() {
    auto fd,fname1 "link1.tmp",fname2 "link2.tmp";

    fd = creat(fname1,386);
    write(fd,"hello, world*n",13);
    close(fd);

    link(fname1,fname2);

    if ( !fork() ) execl("/bin/cat","cat",fname1,NULL);
    wait();
   
    if ( !fork() ) execl("/bin/cat","cat",fname2,NULL);
    wait();
}
