NULL 0;

main() {
    auto fname "unlink.tmp";

    close(2); dup(1); /* 2>&1 */

    if ( !fork() ) execl("/usr/bin/touch","touch",fname,NULL);
    wait();

    if ( !fork() ) execl("/bin/ls","ls",fname,NULL);
    wait();

    unlink(fname);

    if ( !fork() ) execl("/bin/ls","ls",fname,NULL);
    wait();
}

