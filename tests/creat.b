main() {
    auto NULL 0;

    creat("creat.0.tmp",0);
    if ( !fork() ) execl("/usr/bin/stat","stat","-c","%A %n","creat.0.tmp",NULL);
    wait();

    creat("creat.292.tmp",292); /* 0444 */
    if ( !fork() ) execl("/usr/bin/stat","stat","-c","%A %n","creat.292.tmp",NULL);
    wait();

    creat("creat.384.tmp",384); /* 0600 */
    if ( !fork() ) execl("/usr/bin/stat","stat","-c","%A %n","creat.384.tmp",NULL);
    wait();

}
