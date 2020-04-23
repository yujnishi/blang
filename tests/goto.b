main() {
    auto l 0;

    printf("start: %d*n",l);

label1:
    printf("label1: %d*n",l);
    if ( l++ == 0 ) goto label1;

label2:
    printf("label2: %d*n",l);
    if ( l++ == 1 ) goto label1;
    if ( l++ == 3 ) goto label2;

label3:
    printf("label3: %d*n",l);
    if ( l++ <= 9 ) goto label3;

    printf("end: %d*n",l);
}
