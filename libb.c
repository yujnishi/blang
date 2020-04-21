#include <stdarg.h>
#include <asm/stat.h>
#include <asm/termios.h>
#include <sys/syscall.h>
#define NULL ((void*)0)
#define EOF (-1)
#define LC_ALL (6)
typedef unsigned long size_t;
typedef unsigned long time_t;
void* dlopen(const char*,int);
void* dlsym(void*,const char*);
int syscall(int, ...);
struct timeval {
    time_t      tv_sec;     /* 秒 */
    long        tv_usec;    /* マイクロ秒 */
};

int     (*c_chdir)(const char*);
int     (*c_chmod)(const char*,unsigned int);
int     (*c_chown)(const char*,int,int);
int     (*c_close)(int);
int     (*c_creat)(const char*,unsigned int);
int     (*c_dup)(int);
int     (*c_execv)(const char*,const char*[]);
void    (*c_exit)(int);
int     (*c_fflush)(void*);
int     (*c_fork)(void);
int     (*c_fstat)(int,struct stat*);
int     (*c_fputc)(int,void*);
int     (*c_getchar)(void);
int     (*c_getuid)(void);
int     (*c_gettimeofday)(struct timeval*,void*);
void*   (*c_localtime)(time_t*);
int     (*c_link)(const char*,const char*);
int     (*c_mkdir)(const char*,unsigned int);
int     (*c_open)(const char*,int mode);
int     (*c_pipe)(int*);
int     (*c_printf)(const char*,...);
int     (*c_putchar)(int);
long    (*c_read)(int,void*,size_t);
char*   (*c_setlocale)(int,const char*);
int     (*c_stat)(const char*,struct stat*);
size_t  (*c_strftime)(char*,size_t,const char*,void*);
int     (*c_tcgetattr)(int,struct termios*);
int     (*c_tcsetattr)(int,int,struct termios*);
long    (*c_lseek)(int,long,int);
int     (*c_unlink)(const char*);
int     (*c_vprintf)(const char*,va_list);
int     (*c_wait)(void*);
long    (*c_write)(int,const void*,size_t);

int _fstat(int fd,struct stat* st) {
    return syscall(SYS_fstat,fd,st);
}

int _stat(const char* fname,struct stat* st) {
    return syscall(SYS_stat,fname,st);
}


__attribute__((constructor))
void __init() {
    void* h;

    h = dlopen("/lib64/libc.so.6",0x00001/*RTLD_LAZY*/);
    c_chdir         = dlsym(h,"chdir");
    c_chmod         = dlsym(h,"chmod");
    c_chown         = dlsym(h,"chown");
    c_close         = dlsym(h,"close");
    c_creat         = dlsym(h,"creat");
    c_dup           = dlsym(h,"dup");
    c_execv         = dlsym(h,"execv");
    c_exit          = dlsym(h,"exit");
    c_fork          = dlsym(h,"fork");
    c_fflush        = dlsym(h,"fflush");
    c_fputc         = dlsym(h,"fputc");
    c_getchar       = dlsym(h,"getchar");
    c_getuid        = dlsym(h,"getuid");
    c_gettimeofday  = dlsym(h,"gettimeofday");
    c_localtime     = dlsym(h,"localtime");
    c_link          = dlsym(h,"link");
    c_mkdir         = dlsym(h,"mkdir");
    c_open          = dlsym(h,"open");
    c_pipe          = dlsym(h,"pipe");
    c_printf        = dlsym(h,"printf");
    c_putchar       = dlsym(h,"putchar");
    c_read          = dlsym(h,"read");
    c_lseek         = dlsym(h,"lseek");
    c_setlocale     = dlsym(h,"setlocale");
    c_strftime      = dlsym(h,"strftime");
    c_tcgetattr     = dlsym(h,"tcgetattr");
    c_tcsetattr     = dlsym(h,"tcsetattr");
    c_unlink        = dlsym(h,"unlink");
    c_vprintf       = dlsym(h,"vprintf");
    c_wait          = dlsym(h,"wait");
    c_write         = dlsym(h,"write");

    // fstatは見つからないのでこの方法
    c_fstat = _fstat;
    c_stat  = _stat;
}


long b_char(char* s,long i,...) {
    int ret;

    ret = s[i];
    if ( ret == '\0' ) return EOF;
    return ret;
}

long b_chdir(char* dir,...) {
    return c_chdir(dir);
}

long b_chmod(char* fname,long mode,...) {
    return c_chmod(fname,mode);
}

long b_chown(char* fname,long owner,...) {
    return c_chown(fname,owner,-1);
}

long b_close(long fd,...) {
    return c_close(fd);
}

long b_creat(char* fname,long mode,...) {
    return c_creat(fname,mode);
}

long b_ctime(long _t[],char* date,...) {
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

long b_dup(long fd,...) {
    return c_dup(fd);
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

long b_execv(char* cmd,char* _argv[],long argc,...) {
    int i;
    char* argv[1024];

    for ( i = 0; i < argc; i++ ) argv[i] = _argv[i];
    argv[i] = NULL;

    return c_execv(cmd,(const char**) argv);
}

long b_exit(long dummy,...) {
    c_exit(0);
    return 0;
}

long b_fork(long dummy,...) {
    return c_fork();
}

long _setstat(long* b_st,struct stat* c_st) {
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
    b_st[ 0] = c_st->st_dev;
    b_st[ 1] = c_st->st_ino;
    b_st[ 2] = c_st->st_mode;
    b_st[ 3] = c_st->st_nlink;
    b_st[ 4] = c_st->st_uid;
    b_st[ 5] = c_st->st_gid;
    b_st[ 6] = c_st->st_rdev;
    b_st[ 7] = c_st->st_size;
    b_st[ 8] = c_st->st_blksize;
    b_st[ 9] = c_st->st_blocks;
    b_st[10] = c_st->st_atime;
    b_st[11] = c_st->st_mtime;
    b_st[12] = c_st->st_ctime;

    return 0;
}

long b_stat(char* fname,long* st,...) {
    long r;
    struct stat s;

    r = c_stat(fname,&s);
    _setstat(st,&s);

    return r;
}

long b_fstat(long fd,long* st,...) {
    long r;
    struct stat s;

    r = c_fstat(fd,&s);
    _setstat(st,&s);

    return r;
}

long b_getchar(long dummy,...) {
    return c_getchar();
}

long b_getuid(long dummy,...) {
    return c_getuid();
}

long b_pipe(long fd[],...) {
    int p[2];
    int r;

    r = c_pipe(p);
    fd[0] = p[0];
    fd[1] = p[1];
    return r;
}

long b_gtty(long fd,long res[],...) {
    /*
     * TODO 3個値を返すらしい
     * このうちどれを返すかは調べる必要あり
     *
     * unix由来のgttyの構造体
     * struct sgttyb {
     *   char    sg_ispeed;      // input speed
     *   char    sg_ospeed;      // output speed
     *   char    sg_erase;       // erase character
     *   char    sg_kill;        // kill character
     *   short   sg_flags;       // mode flags
     * };
     */
    struct termios buff;
    int r;

    r = c_tcgetattr(fd,&buff);
    res[0] = buff.c_cc[VERASE];
    res[1] = buff.c_cc[VKILL];
    res[2] = buff.c_cflag;

    return r;
}

long b_stty(long fd,long res[],...) {
    // TODO gtty参照
    struct termios buff;
    int r;

    if ( (r=c_tcgetattr(fd,&buff)) ) return r;

    buff.c_cc[VERASE]  = res[0];
    buff.c_cc[VKILL]   = res[1];
    buff.c_cflag       = res[2];
    return c_tcsetattr(fd,TCSANOW,&buff);
}

long b_lchar(char* s,long i,long c,...) {
    int r;

    r = c;
    if ( c == -1 ) c = '\0';
    s[i] = c;

    return r;
}

long b_link(char* old,char* new,...) {
    return c_link(old,new);
}

long b_mkdir(char* dir,long mode,...) {
    return c_mkdir(dir,mode);
}

long b_open(char* fname,long mode,...) {
    return c_open(fname,mode);
}

/*
TODO
error = setuid(id);

    The user-ID of the current process is set to id. A negative number returned indicates an error. (*) 
*/

long b_time(long tm[],...) {
    int r;
    struct timeval tv;

    r = c_gettimeofday(&tv,NULL);
    tm[0] = tv.tv_sec;
    tm[1] = tv.tv_usec;
    return r;
}

long b_printf(char* fmt,...) {
    va_list ap;
    int result;

    va_start(ap,fmt);
    result = c_vprintf(fmt,ap);
    c_fflush(NULL);
    va_end(ap);

    return result;
}

long b_printn(long n,long b,...) {
    int a;

    if ( (a=n/b) != 0 ) b_printn(a,b);
    c_putchar(n % b + '0');

    return 0;
}

long b_putchar(long n,...) {
    if ( n > 0xff ) b_putchar(n>>8);
    c_putchar(n&0xff);
    return 0;
}

long b_read(long fd,char* buf,long size,...) {
    return c_read(fd,buf,size);
}

long b_seek(long fd,long offset,long when,...) {
    return c_lseek(fd,offset,when);
}

long b_unlink(char* name,...) {
    return c_unlink(name);
}

long b_wait(long dummy,...) {
    return c_wait(NULL);
}

long b_write(long fd,char* buf,long size,...) {
    return c_write(fd,buf,size);
}
