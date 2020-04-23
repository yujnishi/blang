NULL 0;

main() {
    auto dname "mkdir.tmp";

    mkdir(dname,493);
    if ( !fork() ) execl("/usr/bin/stat","stat","-c","%A %n",dname,NULL);
    wait();
}
