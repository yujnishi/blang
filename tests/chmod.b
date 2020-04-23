main() {
    auto NULL 0;

    if ( !fork() ) execl("/usr/bin/stat","stat","-c","%A %n","chmod.testdata",NULL);
    wait();
    
    chmod("chmod.testdata",0);
    if ( !fork() ) execl("/usr/bin/stat","stat","-c","%A %n","chmod.testdata",NULL);
    wait();

    chmod("chmod.testdata",292); /* 0444 */
    if ( !fork() ) execl("/usr/bin/stat","stat","-c","%A %n","chmod.testdata",NULL);
    wait();

    chmod("chmod.testdata",384); /* 0600 */
    if ( !fork() ) execl("/usr/bin/stat","stat","-c","%A %n","chmod.testdata",NULL);
    wait();
}
