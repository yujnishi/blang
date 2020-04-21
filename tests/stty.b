tty[3];
sv[3];

main() {
    gtty(1,sv);

    gtty(1,tty);
    printf("1:%d 2:%d 3:%d*n",tty[0],tty[1],tty[2]);

    tty[0] = 8;
    stty(1,tty);
    gtty(1,tty);
    printf("1:%d 2:%d 3:%d*n",tty[0],tty[1],tty[2]);

    stty(1,sv);
    gtty(1,tty);
    printf("1:%d 2:%d 3:%d*n",tty[0],tty[1],tty[2]);
}
