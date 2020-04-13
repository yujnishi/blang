#include <stdarg.h>
#include <asm/stat.h>
#include <sys/syscall.h>
#define NULL ((void*)0)
#define EOF (-1)
#define LC_ALL (6)
typedef unsigned long size_t;
typedef unsigned long time_t;
void* dlopen(const char*,int);
void* dlsym(void*,const char*);
int syscall(int, ...);

int     (*c_chdir)(const char*);
int     (*c_chmod)(const char*,unsigned int);
int     (*c_chown)(const char*,int,int);
int     (*c_close)(int);
int     (*c_creat)(const char*,unsigned int);
int     (*c_execv)(const char*,const char*[]);
void    (*c_exit)(int);
int     (*c_fflush)(void*);
int     (*c_fork)(void);
int     (*c_fstat)(int,struct stat*);
int     (*c_fputc)(int,void*);
void*   (*c_localtime)(time_t*);
int     (*c_printf)(const char*,...);
int     (*c_putchar)(int);
char*   (*c_setlocale)(int,const char*);
size_t  (*c_strftime)(char*,size_t,const char*,void*);
int     (*c_vprintf)(const char*,va_list);
int     (*c_wait)(void*);
long    (*c_write)(int,const void*,size_t);

int _fstat(int fd,struct stat* st) {
    return syscall(SYS_fstat,fd,st);
}


__attribute__((constructor))
void __init() {
    void* h;

    h = dlopen("/lib64/libc.so.6",0x00001/*RTLD_LAZY*/);
    c_chdir      = dlsym(h,"chdir");
    c_chmod      = dlsym(h,"chmod");
    c_chown      = dlsym(h,"chown");
    c_close      = dlsym(h,"close");
    c_creat      = dlsym(h,"creat");
    c_execv      = dlsym(h,"execv");
    c_exit       = dlsym(h,"exit");
    c_fork       = dlsym(h,"fork");
    c_fflush     = dlsym(h,"fflush");
    c_fputc      = dlsym(h,"fputc");
    c_localtime  = dlsym(h,"localtime");
    c_printf     = dlsym(h,"printf");
    c_putchar    = dlsym(h,"putchar");
    c_setlocale  = dlsym(h,"setlocale");
    c_strftime   = dlsym(h,"strftime");
    c_vprintf    = dlsym(h,"vprintf");
    c_wait       = dlsym(h,"wait");
    c_write      = dlsym(h,"write");

    // fstatは見つからないのでこの方法
    c_fstat = _fstat;
}


long b_char(char* s,long i) {
    int ret;

    ret = s[i];
    if ( ret == '\0' ) return EOF;
    return ret;
}

long b_chdir(char* dir) {
    return c_chdir(dir);
}

long b_chmod(char* fname,long mode) {
    return c_chmod(fname,mode);
}

long b_chown(char* fname,long owner) {
    return c_chown(fname,owner,-1);
}

long b_close(long fd) {
    return c_close(fd);
}

long b_creat(char* fname,long mode) {
    return c_creat(fname,mode);
}

long b_ctime(long _t[],char* date) {
    time_t t;
    char* old_locale;
    void* tm;

    t = (time_t)_t[0];
    tm = c_localtime(&t);
    old_locale = c_setlocale(LC_ALL,"C");
    c_strftime(date,17,"%b %d %H:%M:%S",tm);
    c_setlocale(LC_ALL,old_locale);
    return 0;
}

long b_execl(char* cmd,...) {
    int i;
    char* argv[1024];
    va_list vp;

    va_start(vp,cmd);
    i = 0;
    while ( (argv[i]=va_arg(vp,char*)) != NULL ) i++;
    va_end(vp);

    return c_execv(cmd,(const char**)argv);
}

long b_execv(char* cmd,char* _argv[],long argc) {
    int i;
    char* argv[1024];

    for ( i = 0; i < argc; i++ ) argv[i] = _argv[i];
    argv[i] = NULL;

    return c_execv(cmd,(const char**) argv);
}

long b_exit() {
    c_exit(0);
    return 0;
}

long b_fork() {
    return c_fork();
}

long b_fstat(long fd,long* st) {
    long r;
    struct stat s;

    // TODO マニュアル見ると20項目ありそうだけど足りない。調べる
    //       struct stat {
    //           dev_t     st_dev;     /* ファイルがあるデバイスの ID */
    //           ino_t     st_ino;     /* inode 番号 */
    //           mode_t    st_mode;    /* アクセス保護 */
    //           nlink_t   st_nlink;   /* ハードリンクの数 */
    //           uid_t     st_uid;     /* 所有者のユーザ ID */
    //           gid_t     st_gid;     /* 所有者のグループ ID */
    //           dev_t     st_rdev;    /* デバイス ID (特殊ファイルの場合) */
    //           off_t     st_size;    /* 全体のサイズ (バイト単位) */
    //           blksize_t st_blksize; /* ファイルシステム I/O での
    //                                    ブロックサイズ */
    //           blkcnt_t  st_blocks;  /* 割り当てられた 512B のブロック数 */
    //           time_t    st_atime;   /* 最終アクセス時刻 */
    //           time_t    st_mtime;   /* 最終修正時刻 */
    //           time_t    st_ctime;   /* 最終状態変更時刻 */
    //       };
    r = c_fstat(fd,&s);
    st[ 0] = s.st_dev;
    st[ 1] = s.st_ino;
    st[ 2] = s.st_mode;
    st[ 3] = s.st_nlink;
    st[ 4] = s.st_uid;
    st[ 5] = s.st_gid;
    st[ 6] = s.st_rdev;
    st[ 7] = s.st_size;
    st[ 8] = s.st_blksize;
    st[ 9] = s.st_blocks;
    st[10] = s.st_atime;
    st[11] = s.st_mtime;
    st[12] = s.st_ctime;

    return r;
}

/*
TODO
char = getchar( ) ;
    The next character form the standard input file is returned. The character `*e' is returned for an end-of-file. 
id = getuid();

    The user-ID of the current process is returned. (*) 
error = gtty(file, ttystat);

    The teletype modes of the open file designated by file is returned in the 3-word vector ttstat. A negative number returned indicates an error. (*) 
lchar(string, i, char);

    The character char is stored in the i-th character of the string. 
error = link(string1, string2);

    The pathname specified by string2 is created such that it is a link to the existing file specified by string1. A negative number returned indicates an error. (*) 
error = mkdir(string, mode);

    The directory specified by the string is made to exist with the specified access mode. A negative number returned indicates an error. (*) 
file = open(string, mode);

    The file specified by the string is opened for reading if mode is zero, for writing if mode is not zero. The open file designator is returned. A negative number returned indicates an error. (*) 
printf(format, argl, ...);

    See section 9.3 below. 
printn(number, base);

    See section 9.1 below. 
putchar(char) ;

    The character char is written on the standard output file. 
nread = read(file, buffer, count);

    Count bytes are read into the vector buffer from the open file designated by file. The actual number of bytes read are returned. A negative number returned indicates an error. (*) 
error = seek(filet offset, pointer);

    The I/O pointer on the open file designated by file is set to the value of the designated pointer plus the offset. A pointer of zero designates the beginning of the file. A pointer of one designates the current I/O pointer. A pointer of two designates the end of the file. A negative number returned indicates an error. (*) 
error = setuid(id);

    The user-ID of the current process is set to id. A negative number returned indicates an error. (*) 
error = stat(string, status);

    The i-node of the file specified by the string is put in the 20-word vector status. A negative number returned indicates an error. (*) 
error = stty(file, ttystat);

    The teletype modes of the open file designated by file is set from the 3-word vector ttystat. A negative number returned indicates an error. (*) 
time(timev);

    The current system time is returned in the 2-word vector timev. (*) 
error = unlink(string);

    The link specified by the string is removed. A negative number returned indicates an error. (*) 
error = wait( );

    The current process is suspended until one of its child processes terminates. At that time, the child's process-ID is returned. A negative number returned indicates an error. (*) 
nwrite = write(file, buffer, count);

    Count bytes are written out of the vector buffer on the open file designated by file. The actual number of bytes written are returned. A negative number returned indicates an error. (*) 

*/

long b_printf(char* fmt,...) {
    va_list ap;
    int result;

    va_start(ap,fmt);
    result = c_vprintf(fmt,ap);
    c_fflush(NULL);
    va_end(ap);

    return result;
}

long b_putchar(long n) {
    if ( n > 0xff ) b_putchar(n>>8);
    c_putchar(n&0xff);
    return 0;
}

long b_wait() {
    return c_wait(NULL);
}

long b_write(long fd,char* buf,long size) {
    return c_write(fd,buf,size);
}
