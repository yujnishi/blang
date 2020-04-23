now[2] 0,0;

main() {
    auto buf "Mmm dd hh:mm:ss";

    ctime(now,buf);
    printf("now1 is *'%s*'*n",buf);

    now[0] = 1586066828;
    ctime(now,buf);
    printf("now2 is *'%s*'*n",buf);
}
