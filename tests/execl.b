main() {
    auto NULL 0;
    if ( !fork() ) execl("/bin/echo","echo","hoge","fuga","foo","bar",NULL);
    wait();
}
