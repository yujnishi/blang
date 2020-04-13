main() {
    auto fd,fname "close.tmp",NULL 0;

    fd = creat( fname, 384 /* 0600 */);
    write(fd,"Hello World.",12);
    printf("1st close return is %d*n",close(fd));
    printf("2nd close return is %d*n",close(fd));
    printf("===*n");

    if ( !fork() ) execl("/bin/cat","cat",fname,NULL);
    wait();
}

