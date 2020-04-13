main() {
    if ( !fork() ) execl("/usr/bin/pwd","pwd",0);
    wait();
    chdir("/");
    if ( !fork() ) execl("/usr/bin/pwd","pwd",0);
    wait();
}
