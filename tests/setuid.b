main() {
    auto err,uid;

    uid = getuid();

    err = setuid(1);
    if ( uid == 0 ) {
        if ( getuid() == 1 ) putchar('OK*n');
        else                 putchar('NG*n');
    } else {
        if ( err != 0 )      putchar('OK*n');
        else                 putchar('NG*n');
    }

}
