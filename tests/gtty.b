tty[3];

main() {
    printf("ret = %d*n",gtty(1,tty));
    printf("0: %d*n1:%d*n2:%d*n",tty[0],tty[1],tty[2]);
}
