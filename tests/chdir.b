main() {
    chdir("/");
    if ( !fork() ) execl("/usr/bin/pwd","pwd",0);
    wait();
    chdir("/etc");
    if ( !fork() ) execl("/usr/bin/pwd","pwd",0);
    wait();
}
