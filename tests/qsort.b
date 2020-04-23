list[10]
    "a programing language",
    "b language",
    "BASIC",
    "BCPL",
    "c language",
    "COBOL",
    "FORTRAN",
    "java",
    "LISP",
    "pascal";
tm[2];

display() {
    auto i;

    i = 0;
    while ( i < 10 ) printf("%d: %s*n",i,list[i++]);
    printf("----*n");
}

/* 適当 */
seed 123;
rand() {
    seed = 7*seed+3;
    seed =* (seed>=0) ? 1 : -1;
    return(seed%10);
}

swap(a,b) {
    auto tmp;

    tmp = list[a];
    list[a] = list[b];
    list[b] =tmp;
}

shuffle() {
    auto i;

    time(tm);
    seed = tm[0];

    i = 0;
    while ( ++i < 100 ) swap(rand(),rand());
}

compare(a,b) {
    auto r;

    r = 0;
    if ( list[a] < list[b] ) r = -1;
    if ( list[a] > list[b] ) r = 1;
    return(r);
}

qsort(start,end) {
    auto pivot,i,j;

    if ( start == end ) return;
    if ( start+1 == end ) {
        if ( compare(start,end) <= 0 ) swap(start,end);
        return;
    }

    pivot = i = start;
    j = end;
    while ( i < j ) {
        while ( (i<j) & (compare(pivot,i)<=0) ) i++;
        while ( (i<j) & (compare(pivot,j)>0 ) ) j--;

        if ( (j<=end) & (i<j) ) swap(i++,j);
    }

    if ( j==start ) { /* 全てがpivotより大きい */
        qsort(start+1,end);
        return;
    }
    if ( i==end ) { /* 全てがpivotより小さい */
        if ( compare(start,end) <= 0 ) swap(start,end);
        qsort(start,end-1);
        return;
    }

    qsort(pivot,i-1);
    qsort(j,end);
}

main() {
    auto i,is_shuffle 0;
    display();

    shuffle();
    i = 0;
    while ( i < 9 ) {
        if ( list[i] > list[i+1] ) is_shuffle = 1;
        i++;
    }
    if ( is_shuffle ) printf("shuffle ok*n----*n");
    else              printf("shuffle ng*n----*n");
    /* display(); */

    qsort(0,9);
    display();
}
