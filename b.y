%{
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <llvm-c/Core.h>
#include "b.tab.h"


int yyerror(char const*);

int is_pred = 0;
int vnum = 0;
int getvnum() {
    int ret = vnum;
    vnum++;
    return ret;
}

int prev_vnum = 0;
int set_block() {
    if ( is_pred == 0 ) return 0;
    //if ( prev_vnum == vnum ) return 0;
    printf("; is_pred[%d] set block is %%%d\n",is_pred,getvnum());
    is_pred = 0;
    prev_vnum = vnum;
    return vnum-1;
}

int lnum = 0;
int getlnum() {
    int ret = lnum;
    lnum++;
    return ret;
}

int snum = 0;
int getsnum() {
    int ret = snum;
    snum++;
    return ret;
}

int isret = 0;

struct tree;
struct type {
#define TYPE_NONE 0
#define TYPE_BASIC 1
#define TYPE_ARRAY 2
#define TYPE_FUNCTION 3
#define TYPE_POINTER 4
    int type;
    union {
        char* name;
        struct { struct type* type; int num; } arr;
        struct type* base;
        struct tree* ext;
    };
};

struct val_list {
    int is_define;
    int is_global;
    struct type* type;
    char name[1024];
    struct val_list* next;
};

#define TREE_LIST (EOT+1)
#define TREE_GLOBAL (EOT+2)
#define TREE_GLOBAL_ARRAY (EOT+3)
#define TREE_DEFUN (EOT+4)
#define TREE_LABEL (EOT+5)
#define TREE_EMPTY (EOT+6)
#define TREE_STORE (EOT+7)
#define TREE_ADDR (EOT+8)
#define TREE_REF (EOT+10)
#define TREE_ELVIS (EOT+14)
#define TREE_CALL (EOT+15)
#define TREE_VAL (EOT+16)
#define TREE_ (EOT+5)
struct tree {
    int type;
    union {
        char s[256];
        struct { struct tree *t1,*t2,*t3; } t;
        struct { struct tree *p,*next; } l;
        struct val_list* v;
    };
};
struct tree* root;

struct tree* new_s(int t,char* s) {
    struct tree* r;

    r = calloc(sizeof(struct tree),1);
    r->type = t;
    strcpy(r->s,s);
    return r;
}

struct tree* new_l(int t,struct tree* p,struct tree* n) {
    struct tree* r;

    r = calloc(sizeof(struct tree),1);
    r->type   = t;
    r->l.p    = p;
    r->l.next = n;
    return r;
}

struct tree* new_t(int t,struct tree* t1,struct tree* t2,struct tree* t3) {
    struct tree* r;

    r = calloc(sizeof(struct tree),1);
    r->type = t;
    r->t.t1 = t1;
    r->t.t2 = t2;
    r->t.t3 = t3;
    return r;
}

struct tree* add_list(struct tree* l,struct tree* c) {
    struct tree* p;

    if ( l == NULL ) return new_l(TREE_LIST,c,NULL);
    for ( p = l; p->l.next; p = p->l.next );
    p->l.next = new_l(TREE_LIST,c,NULL);
    return l;
}

struct tree* find(struct tree* l,char* name) {
    struct tree* p;

    for ( p = l; p; p = p->l.next ) {
        if ( strcmp(p->l.p->t.t1->s,name) ) continue;

        return p;
    }
    return NULL;
}

struct type type_auto,type_autoptr,type_i8;

struct type* new_type_array(struct type* t,int n) {
    struct type* p;

    p = calloc(sizeof(struct type),1);
    p->type = TYPE_ARRAY;
    p->arr.type = t;
    p->arr.num = n;

    return p;
}
struct type* new_type(int type,struct tree* t) {
    struct type* p;

    p = calloc(sizeof(struct type),1);
    p->type = type;
    p->ext = t;
    return p;
}

int init_type() {
    type_auto.type = TYPE_BASIC;
    type_auto.name = "i64";

    type_autoptr.type = TYPE_POINTER;
    type_autoptr.base = &type_auto;

    type_i8.type = TYPE_BASIC;
    type_i8.name = "i8";

    return 0;
}

struct val_list* val_stack[64];
int val_sp = 0;

int del_val_list(struct val_list* p) {
    if ( p == NULL ) return 0;
    if ( p->next ) del_val_list(p->next);
    free(p);
    return 0;
}

int push_val_stack() {
    val_sp++;
    val_stack[val_sp] = NULL;
    return 0;
}
int pop_val_stack() {
    del_val_list(val_stack[val_sp]);
    val_stack[val_sp] = NULL;
    val_sp--;
    return 0;
}

struct val_list* add_val(int is_define,int is_global,struct type* type,char* name) {
    struct val_list *p,*q;
    int vsp;

    vsp = is_global ? 0 : val_sp;
    p = calloc(sizeof(struct val_list),1);
    p->is_define = is_define;
    p->is_global = is_global;
    p->type = type;
    strcpy(p->name,name);

    if ( val_stack[vsp] == NULL ) { val_stack[vsp] = p; return p; }
    for ( q = val_stack[vsp]; q->next; q = q->next ) if ( !strcmp(q->name,name) ) {
        free(p);
        return NULL;
    }
    q->next = p;
    return p;
}

struct tree* new_r(struct type* type) {
    char buf[32];
    struct tree* r;

    r = calloc(1,sizeof(struct tree));
    r->type = TREE_VAL;

    sprintf(buf,"%d",getvnum());
    r->v = add_val(1,0,type,buf);

    return r;
}

struct val_list* find_val(char* name) {
    struct val_list* p;
    int sp;

    for ( sp = val_sp; sp >= 0; sp-- ) for ( p = val_stack[sp]; p; p = p->next ) {
        if ( !strcmp(p->name,name) ) return p;
    }

    return NULL;
}

int tostr_type(char* buf,struct type* t) {
    int n;

    n = 0;
    if ( t == NULL ) t = &type_auto;
    if ( t->type == TYPE_BASIC ) n = sprintf(buf,"%s",t->name);
    else if ( t->type == TYPE_ARRAY ) {
        n =  sprintf(&buf[n],"[%d x ",t->arr.num);
        n += tostr_type(&buf[n],t->arr.type);
        n += sprintf(&buf[n],"]");
    } else if ( t->type == TYPE_POINTER ) {
        n =  tostr_type(&buf[n],t->base);
        n += sprintf(&buf[n],"*");
    }

    return n;
}

char* tostr_val(char* buf,int is_type,struct val_list* val) {
    char* p;

    p = buf;
    if ( is_type ) p += tostr_type(p,val->type);
    if ( is_type ) p += sprintf(p," ");
    sprintf(p,"%c%s",val->is_global?'@':'%',val->name);

    return buf;
}


int yylex();

#define CASE(t,n) ((t)==(n))?#n:
#define DEFAULT "None"
#define TYPE_NAME(t) ( \
          CASE(t,NAME) \
          CASE(t,CHAR) \
          CASE(t,STRING) \
          CASE(t,DIGIT) \
          CASE(t,INC) \
          CASE(t,DEC) \
          CASE(t,EQ) \
          CASE(t,NE) \
          CASE(t,LT) \
          CASE(t,LE) \
          CASE(t,GT) \
          CASE(t,GE) \
          CASE(t,LSHIFT) \
          CASE(t,RSHIFT) \
          CASE(t,AUTO) \
          CASE(t,EXTRN) \
          CASE(t,IF) \
          CASE(t,ELSE) \
          CASE(t,GOTO) \
          CASE(t,SWITCH) \
          CASE(t,CASE) \
          CASE(t,RETURN) \
          CASE(t,WHILE) \
          CASE(t,ASSIGN) \
          CASE(t,TREE_LIST) \
          CASE(t,TREE_GLOBAL) \
          CASE(t,TREE_GLOBAL_ARRAY) \
          CASE(t,TREE_DEFUN) \
          CASE(t,TREE_LABEL) \
          CASE(t,TREE_EMPTY) \
          CASE(t,TREE_STORE) \
          CASE(t,TREE_ADDR) \
          CASE(t,TREE_REF) \
          CASE(t,TREE_ELVIS) \
          CASE(t,TREE_CALL) \
          CASE(t,TREE_VAL) \
          DEFAULT)

int dump(struct tree* root,int indent) {
    int i;

    if ( root == NULL ) return 0;
    for ( i = 0; i < indent*2; i++ ) printf(" ");
    printf("%s(%02x[%c]):\n",TYPE_NAME(root->type),root->type,isprint(root->type)?root->type:'.');
    switch ( root->type ) {
    case NAME:
    case CHAR:
    case DIGIT:
    case STRING:
    case TREE_LABEL:
        for ( i = 0; i < indent*2; i++ ) printf(" ");
        printf("'%s'\n",root->s);
        break;
    default:
        dump(root->t.t1,indent+1);
        dump(root->t.t2,indent+1);
        dump(root->t.t3,indent+1);
    }
    return 0;
}

char name_buf[1024];
char* gencode_name(struct tree* v) {
    struct val_list* p;

    name_buf[0] = '\0';
    p = find_val(v->s);
    if ( p == NULL ) {
        fprintf(stderr,"unknown symbol %s\n",v->s);
        abort();
        exit(1);
    }
    sprintf(name_buf,"%c%s",p->is_global?'@':'%',p->name);
    return name_buf;
}

int gencode_val(char* buf,struct tree* v,int is_type,int is_ptr) {
    char *ptr;
    char *tp;
    char *sep;

    ptr = is_ptr ? "*" : "";
    tp = is_type ? "i64" : "";
    sep = (is_type || is_ptr) ? " " : "";
    buf[0] = '\0';
    if ( ((long)v) < 1024 )     sprintf(buf,"%s%s%s%%__val%d",tp,ptr,sep,(int)(long)v);
    else if ( v->type == NAME ) {
        struct val_list* p;

        p = find_val(v->s);
        if ( p == NULL || (p->type && p->type->type == TYPE_BASIC) ) sprintf(buf,"%s%s%s%s",tp,ptr,sep,gencode_name(v));
        else {
            char tstr[32];
            char* tname;

            tostr_type(tstr,p->type);
            tname = p->type->arr.type->name;
            //sprintf(buf,"%s*%s getelementptr inbounds (%s, %s* %s, i64 0, i64 0)",tname,ptr,tstr,tstr,gencode_name(v));
            sprintf(buf,"i64%s ptrtoint (%s* %s to i64%s)",ptr,tstr,gencode_name(v),ptr);
        }
    }
    else if ( v->type == STRING ) {
        char* s;
        char* d;

        s = v->s;
        d = buf;
        for ( ; *s; s++ ) {
            if ( isprint(*s) && !strchr("\\\"",*s) ) *d = *s;
            else {
                *d = '\\';
                d++;
                *d = "0123456789ABCDEF"[(*s>>4)&0xf];
                d++;
                *d = "0123456789ABCDEF"[*s&0xf];
            }
            d++;
        }
        strcpy(d,"\\00");
    } else if ( v->type == CHAR ) {
        char* s;
        int n,m;

        n = 0;
        for ( s = v->s; *s; s++ ) {
            if ( s != v->s ) n <<= 8;
           
            if ( *s == '*' ) {
                s++;
                switch ( *s ) {
                case 'n': n |= '\n'; break;
                case 'r': n |= '\r'; break;
                case 't': n |= '\t'; break;
                case 'e': n |= EOF ; break;
                case '0': n |= '\0'; break;
                case '(': n |= '{' ; break;
                case ')': n |= '}' ; break;
                case '*': n |= '*' ; break;
                case '"': n |= '"' ; break;
                case '\'': n |= '\'' ; break;
                default:
                    sscanf(s,"%02X",&m);
                    n |= m;
                    break;
                }
            } else n |= *s;
        }
        sprintf(buf,"%s %d",tp,n);
    } else if ( v->type == DIGIT ) {
        sprintf(buf,"%s %d",tp,atoi(v->s));
    } else if ( v->type == TREE_VAL ) {
        tostr_val(buf,is_type,v->v);
    }
    return 0;
}

int gencode_ainit(struct tree* vals) {
    struct tree* p;
    char* delim = "";

    printf("[");
    for ( p = vals; p; p = p->l.next ) {
        char buf[256];

        gencode_val(buf,p->l.p,1,0);
        printf("%s%s",delim,buf);
        delim = ", ";
    }
    printf("]");
    return 0;
}

int debug = 0;
#define output(op,...) gencode_output(__FILE__,__LINE__,op,__VA_ARGS__)
struct tree* gencode_output(char* file,int line,char* op,...) {
    FILE* fi;
    va_list ap;
    struct tree* ret;
    char buf[256];
    char* p;

    isret = 0;
    ret = NULL;
    fi = stdout;
    va_start(ap,op);
    for ( p = op; *p; p++ ) {
        if ( *p != '%' ) { fputc(*p,fi); continue; }

        p++;
        switch ( *p ) {
        case '%': fputc('%',fi); break;
        case 'd': fprintf(fi,"%d",va_arg(ap,int)); break;
        case 's': fprintf(fi,"%s",va_arg(ap,char*)); break;
        case 'r': fprintf(fi,"%%__val%d",ret=(void*)(long)getvnum()); break;
        case 'v':
            gencode_val(buf,va_arg(ap,struct tree*),0,0);
            fprintf(fi,"%s",buf);
            break;
        case 'V':
            gencode_val(buf,va_arg(ap,struct tree*),1,0);
            fprintf(fi,"%s",buf);
            break;
        case 'P':
            gencode_val(buf,va_arg(ap,struct tree*),1,1);
            fprintf(fi,"%s",buf);
            break;
        default:
            fprintf(stderr,"unknown error\n");
            abort();
            exit(1);
        }
    }
    va_end(ap);
    if ( debug ) fprintf(fi," ; [[%s(%d)]]",file,line);
    fputc('\n',fi);

    return ret;
}


struct tree* gencode_stmt(struct tree* stmt) {
    int l_then,l_else,l_endif,l_while,l_do,l_end,l_true,l_false,result;
    int len;
    char* ftype;
    struct tree* a;
    struct tree* ret;
    struct tree* ret2;
    struct tree* ret3;
    struct tree* args;
    struct tree* p;
    struct tree* q;
    char buf[256];
    char buf2[256];
    char type[256];
    char* delim;
    char* s;
    int n;
    struct val_list* v;
    int lnext;

    ret = NULL;
    if ( stmt == NULL ) return NULL;
    switch ( stmt->type ) {
    case EXTRN:
        for ( a = stmt->t.t1; a; a = a->l.next ) add_val(0,1,NULL,a->l.p->s);
        ret = NULL;
        break;
    case AUTO:
        add_val(1,0,&type_auto,stmt->t.t1->s);
        output("  %%%s = alloca i64",stmt->t.t1->s);
        if ( stmt->t.t2 ) output("  store %V, i64* %%%s",stmt->t.t2,stmt->t.t1->s);
        break;
    case IF: 
        ret = output("  %r = icmp ne %V, 0",gencode_stmt(stmt->t.t1));
        output("  br i1 %v, label %%__la%d, label %%__la%d",ret,l_then=getlnum(),l_else=getlnum());is_pred = 1;
        output("  br label %%__la%d",l_then,set_block());
        output("__la%d:",l_then);
        ret = gencode_stmt(stmt->t.t2);
        output("  br label %%__la%d",l_endif=getlnum());is_pred=1;
        output("  br label %%__la%d",l_else,set_block());
        output("__la%d:",l_else);
        ret = gencode_stmt(stmt->t.t3);
        output("  br label %%__la%d",l_endif,set_block());
        output("__la%d:",l_endif);
        break;
    case TREE_ELVIS:
        ret = output("  %r = icmp ne %V, 0",gencode_stmt(stmt->t.t1));
        output("  br i1 %v, label %%__la%d, label %%__la%d",ret,l_true=getlnum(),l_false=getlnum());is_pred=1;
        output("  br label %%__la%d",l_true,set_block());
        output("__la%d:",l_true);
        ret = gencode_stmt(stmt->t.t2);
        output("  br label %%__la%d",l_end=getlnum(),set_block());
        output("__la%d:",l_false);
        ret2 = gencode_stmt(stmt->t.t3);
        output("  br label %%__la%d",l_end,set_block());
        output("__la%d:",l_end);
        ret = output("  %r = phi i64 [%v,%%__la%d], [%v,%%__la%d]",ret,l_true,ret2,l_false);is_pred = 1;
        break;
    case '!':
        ret = output("  %r = icmp ne %V, 0",gencode_stmt(stmt->t.t1));
        ret = output("  %r = xor i1 %v, true",ret);
        ret = output("  %r = zext i1 %v to i64",ret);
        break;
    case '+':
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        ret2 = gencode_stmt(stmt->t.t1);
        if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
        ret = output("  %r = add nsw %V, %v",ret2,ret);
        break;
    case '-':
        if ( stmt->t.t2 ) { 
            ret = gencode_stmt(stmt->t.t2);
            if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
            ret2 = gencode_stmt(stmt->t.t1);
            if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
            ret = output("  %r = sub nsw %V, %v",ret2,ret);
        } else {
            ret = gencode_stmt(stmt->t.t1);
            if ( stmt->t.t1->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
            ret = output("  %r = sub nsw i64 0, %v",ret);
        }
        break;
    case '*':
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        ret2 = gencode_stmt(stmt->t.t1);
        if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
        ret = output("  %r = mul %V, %v",ret2,ret);
        break;
    case '/':
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        ret2 = gencode_stmt(stmt->t.t1);
        if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
        ret = output("  %r = sdiv %V, %v",ret2,ret);
        break;
    case '%':
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        ret2 = gencode_stmt(stmt->t.t1);
        if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
        ret = output("  %r = srem %V, %v",ret2,ret);
        break;
    case '&':
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        ret2 = gencode_stmt(stmt->t.t1);
        if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
        ret = output("  %r = and %V, %v",ret2,ret);
        break;
    case LT:
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        ret2 = gencode_stmt(stmt->t.t1);
        if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
        ret = output("  %r = icmp slt %V, %v",ret2,ret);
        ret = output("  %r = zext i1 %v to i64",ret);
        break;
    case LE:
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        ret2 = gencode_stmt(stmt->t.t1);
        if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
        ret = output("  %r = icmp sle %V, %v",ret2,ret);
        ret = output("  %r = zext i1 %v to i64",ret);
        break;
    case GT:
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        ret2 = gencode_stmt(stmt->t.t1);
        if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
        ret = output("  %r = icmp sgt %V, %v",ret2,ret);
        ret = output("  %r = zext i1 %v to i64",ret);
        break;
    case GE:
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        ret2 = gencode_stmt(stmt->t.t1);
        if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
        ret = output("  %r = icmp sge %V, %v",ret2,ret);
        ret = output("  %r = zext i1 %v to i64",ret);
        break;
    case EQ:
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        ret2 = gencode_stmt(stmt->t.t1);
        if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
        ret = output("  %r = icmp eq %V, %v",ret2,ret);
        ret = output("  %r = zext i1 %v to i64",ret);
        break;
    case NE:
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        ret2 = gencode_stmt(stmt->t.t1);
        if ( stmt->t.t1->type == TREE_REF ) ret2 = output("  %r = load i64, %P",ret2);
        ret = output("  %r = icmp ne %V, %v",ret2,ret);
        ret = output("  %r = zext i1 %v to i64",ret);
        break;
    case TREE_ADDR:
        if ( stmt->t.t1->type == NAME ) ret = output("  %r = ptrtoint i64* %%%s to i64",stmt->t.t1->s);
        else                            ret = gencode_stmt(stmt->t.t1);
        break;
    case TREE_STORE:
         ret = gencode_stmt(stmt->t.t1);
         ret = output("  %r = inttoptr %V to i8*",ret);
         ret = output("  %r = bitcast i8* %v to i64*",ret);
         ret = output("  %r = load i64, i64* %v",ret);
         break;
    case ASSIGN:
        ret = gencode_stmt(stmt->t.t2);
        if ( stmt->t.t2->type == TREE_REF ) ret = output("  %r = load i64, %P",ret);
        // ret2 = gencode_stmt(new_t(TREE_ADDR,stmt->t.t1,NULL,NULL));
        ret2 = stmt->t.t1;
        if ( stmt->t.t1->type != NAME ) ret2 = gencode_stmt(stmt->t.t1);
        output("  store %V, %P",ret,ret2);
        ret = output("  %r = load i64, %P",ret2);
        break;
    case TREE_CALL:
        n = 0;
        args = NULL;
        for ( p = stmt->t.t2; p; p = p->l.next ) {
            struct tree* a;

            a = gencode_stmt(p->l.p);
            if ( p->l.p->type == TREE_REF ) a = output("  %r = load i64, %P",a);
            args = add_list(args,a);
            n++;
        }
        ftype = "(...)";
        if ( (v=find_val(stmt->t.t1->s)) == NULL ) {
            if ( add_val(0,1,new_type(TYPE_FUNCTION,new_t(TREE_DEFUN,stmt->t.t1,(void*)(long)n,NULL)),stmt->t.t1->s) == NULL ) {
                fprintf(stderr,"redefine %s\n",stmt->t.t1->s);
                abort();
                exit(1);
            }
        } else if ( v->type && v->type->type != TYPE_FUNCTION ) {
            fprintf(stderr,"not function %s\n",stmt->t.t1->s);
            abort();
            exit(1);
        } else if ( v->is_define ) ftype = "";
        printf("  %%__val%d = call i64 %s %s(",ret=(void*)(long)getvnum(),ftype,gencode_name(stmt->t.t1));
        delim = "";
        for ( p = args; p; p = p->l.next ) {
            char* type;

            type = "i64";
            gencode_val(buf,p->l.p,1,0);
            printf("%s %s",delim,buf);
            delim = ",";
        }
        printf(")\n");
        //is_pred = 1;
        break;
    case GOTO:
        output("  br label %%%s",stmt->t.t1->s);is_pred=1;
        break;
    case WHILE:
        output("  br label %%__la%d",l_while=getlnum(),set_block());
        output("__la%d:",l_while);
        ret2 = gencode_stmt(stmt->t.t3);
        ret = gencode_stmt(stmt->t.t1);
        ret = output("  %r = icmp ne %V, 0",ret);
        output("  br i1 %v, label %%__la%d, label %%__la%d",ret,l_do=getlnum(),l_end=getlnum());is_pred = 1;
        output("  br label %%__la%d",l_do,set_block());
        output("__la%d:",l_do);
        ret = gencode_stmt(stmt->t.t2);
        output("  br label %%__la%d",l_while);is_pred = 1;
        output("  br label %%__la%d",l_end,set_block());
        output("__la%d:",l_end);
        break;
    case TREE_LIST:
        for ( p = stmt; p; p = p->l.next ) ret = gencode_stmt(p->l.p);
        break;
    case INC:
    case DEC:
        ret = stmt->t.t1 ? stmt->t.t1 : stmt->t.t2;
        s = ret->s;
        ret = gencode_stmt(ret);
        ret2 = output("  %r = %s nsw %V, 1",stmt->type==INC?"add":"sub",ret);
        output("  store %V, i64* %%%s",ret2,s);
        if ( stmt->t.t2 ) ret = ret2;
        break;
    case TREE_REF:
        ret = gencode_stmt(stmt->t.t2);
        strcpy(buf2,gencode_name(stmt->t.t1));
        tostr_type(type,find_val(stmt->t.t1->s)->type);
        ret = output("  %r = getelementptr inbounds %s, %s* %s, i64 0, i64 %v",type,type,buf2,ret);
        break;
    case SWITCH:
        ret = gencode_stmt(stmt->t.t1);
        gencode_val(buf,ret,0,0);
        for ( p = stmt->t.t2; p; p = p->l.next ) {
            int lnum;
            if ( p->l.p->type != CASE ) continue;

            ret2 = output("  %r = icmp eq %V, %v",ret,p->l.p->t.t1);
            output("  br i1 %v, label %%__la%d, label %%__la%d",ret2,lnum=getlnum(),lnext=getlnum());is_pred = 1;
            output("  br label %%__la%d",lnext,set_block());
            output("__la%d:",lnext);

            p->l.p->type = TREE_LABEL;
            sprintf(p->l.p->s,"__la%d",lnum);
        }
        output("  br label %%__la%d",lnext=getlnum(),set_block());is_pred = 1;
        gencode_stmt(stmt->t.t2);
        output("  br label %%__la%d",lnext,set_block());
        output("__la%d:",lnext);
        break;
    case RETURN:
        if ( stmt->t.t1 ) {
            ret = gencode_stmt(stmt->t.t1);
            gencode_val(buf,ret,0,0);
            ret = NULL;
        } else strcpy(buf,"0");
        output("  ret i64 %s",buf);
        isret = 1;
        is_pred = 1;
        getvnum();
        //set_block();
        break;
    case TREE_LABEL:
        output("  br label %%%s",stmt->s,set_block());
        output("%s:",stmt->s);
        break;
    case NAME:
        v = find_val(stmt->s);
        if ( v && v->type == NULL ) v->type = &type_auto;
        if ( v && v->type && v->type->type == TYPE_BASIC ) 
          ret = output("  %r = load i64, %P",stmt);
        else ret = stmt;
        break;
    case CHAR:
    case DIGIT:
        ret = stmt;
        break;
    default:
        dump(stmt,0);
        break;
    }

    return ret;
}

int gencode_decl(struct tree* stmts) {
    struct tree* p;
    struct tree* ret;

    for ( p = stmts; p; p = p->l.next ) ret = gencode_stmt(p->l.p);
    return 0;
}

int gencode_func(char* name,struct tree* vals,struct tree* stmts) {
    struct tree* p;
    char* delim = "";
    struct tree* val;
    int v;

    /* TODO 全てを可変長引数に */
    val = NULL;
    printf("define i64 @%s",name);
    v = isret = vnum = lnum = is_pred = prev_vnum = 0;
    printf("(");
    for ( p = vals; p; p = p->l.next ) { printf("%s i64",delim,getvnum()); delim = ", "; }
    printf(") {\n");
    push_val_stack();
    getvnum();
    for ( p = vals; p; p = p->l.next ) {
        printf("  %%%s = alloca i64\n",p->l.p->s);
        printf("  store i64 %%%d, i64* %%%s\n",v,p->l.p->s);
        val = add_list(val,new_t(AUTO,p->l.p,NULL,NULL));
        add_val(1,0,&type_auto,p->l.p->s);
        v++;
    }
    gencode_decl(stmts);
    if ( !isret ) printf("  ret i64 0\n");
    pop_val_stack();
    printf("}\n");
    return 0;
}

int gencode_global(struct tree* def) {
    char* name;
    struct tree* size;
    struct type* type;

    name = def->t.t1->s;
    if ( def->type == TREE_GLOBAL )
        if ( def->t.t2 == NULL ) printf("@%s = global i64",name);
        else {
            char buf[1024];

            gencode_val(buf,def->t.t2,1,0);
            printf("@%s = global %s",name,buf);
        }
    if ( def->type == TREE_GLOBAL_ARRAY )
        if ( def->t.t3 == NULL ) printf("@%s = global [%s x i64] zeroinitializer",name,def->t.t2->s);
        else                     printf("@%s = global [%s x i64] ",name,def->t.t2->s),gencode_ainit(def->t.t3);
    printf("\n");

    type = def->type == TREE_GLOBAL_ARRAY ? new_type_array(&type_auto,atoi(def->t.t2->s)) : &type_auto;
    add_val(1,1,type,name);
    return 0;
}

int strescape(char* d,char* s) {
    int len;

    len = 0;
    while ( *s ) {
        if ( strchr("\r\n\e\b\t",*s) ) {
            sprintf(d,"\\%02X",*s);
            d += 2;
        } else if ( *s == '*' ) {
            int c;
            char* from = "rnebt()*'\"";
            char* to   = "\r\n\e\b\t{}*'\"";
            s++;
            c = to[strchr(from,*s)-from];
            sprintf(d,"\\%02X",c);
            d += 2;
        } else  *d = *s;
        s++;
        d++;
        len++;
    }
    sprintf(d,"\\00");
    d += 3;
    len++;
    *d = '\0';

    return len;
}

struct tree* gencode_allocstr_node(struct tree* node) {
    int len;
    char buf[256];
    char tstr[32];
    char str[1024];
    struct val_list* v;

    if ( node == NULL ) return NULL;
    if ( node->type != STRING ) return NULL;

    sprintf(buf,".str.%d",getsnum());
    len = strescape(str,node->s);
    v = add_val(1,1,new_type_array(&type_i8,len),buf);
    tostr_type(tstr,v->type);

    printf("@%s = global %s c\"%s\"\n",buf,tstr,str);
    return new_s(NAME,buf);
}

int gencode_allocstr(struct tree* root) {
    struct tree* n;
    if ( root == NULL ) return 0;

    switch ( root->type ) {
    case NAME:
    case CHAR:
    case DIGIT:
    case STRING:
    case TREE_LABEL:
        break;
    default:
        gencode_allocstr(root->t.t1);
        gencode_allocstr(root->t.t2);
        gencode_allocstr(root->t.t3);
        if ( n=gencode_allocstr_node(root->t.t1) ) root->t.t1=n;
        if ( n=gencode_allocstr_node(root->t.t2) ) root->t.t2=n;
        if ( n=gencode_allocstr_node(root->t.t3) ) root->t.t3=n;
        break;
    }

    return 0;
}

int gencode(struct tree* root) {
    struct val_list* v;
    struct tree* p;

    if ( root == NULL ) return 0;

    // replace string
    gencode_allocstr(root);

    // global val
    for ( p = root; p; p = p->l.next ) {
        struct tree* def;
        char* name;

        def = p->l.p;
        switch ( def->type ) {
        case TREE_GLOBAL:
        case TREE_GLOBAL_ARRAY:
            gencode_global(def);
            break;
        case TREE_DEFUN:
            break;
        default:
            fprintf(stderr,"unknown type\n");
            break;
        }
    }

    // function
    for ( p = root; p; p = p->l.next ) {
        struct tree* def;
        char* name;

        def = p->l.p;
        switch ( def->type ) {
        case TREE_GLOBAL:
        case TREE_GLOBAL_ARRAY:
            break;
        case TREE_DEFUN:
            name = def->t.t1->s;
            add_val(1,1,new_type(TYPE_FUNCTION,def),name);
            gencode_func(name,def->t.t2,def->t.t3);
            break;
        default:
            fprintf(stderr,"unknown type\n");
            break;
        }
    }

    // declare undef function
    for ( v = val_stack[0]; v; v = v->next ) {
        if ( v->type && v->type->type != TYPE_FUNCTION ) continue;
        if ( v->is_define ) continue;

        printf("declare i64 @%s(...)\n",v->name);
    }
    return 0;
}

%}

%union {
    char s[2048];
    struct tree* t;
}
/* TODO 最初autoからプログラム始めるとパース結果が変になる */
%start start
%type <t> lvalue rvalue assign inc-dec unary rvalue-list auto-defs ival-list statement statement-list
%type <t> name-list
%type <t> constant ival
%type <t> extrn-list
%type <t> program definition
%right '='
%left '?' ':'
%left EQ NE LT LE GT GE
%left LSHIFT RSHIFT
%left '+' '-'
%left '*' '/' '%' 
%right INC DEC
%token <s> ASSIGN
%token <s> NAME
%token <s> CHAR
%token <s> STRING
%token <s> DIGIT
%token INC
%token DEC
%token EQ
%token NE
%token LT
%token LE
%token GT
%token GE
%token LSHIFT
%token RSHIFT
%token AUTO EXTRN IF ELSE GOTO SWITCH CASE RETURN WHILE
%token EOT


%%
start: program { return gencode($1); }
     ;

program: /* empty */ { $$ = NULL; }
  |      definition { $$ = add_list(NULL,$1); }
  |      program definition { $$ = add_list($1,$2); }
  ;

definition: NAME ';' { $$ = new_t(TREE_GLOBAL,new_s(NAME,$1),NULL,NULL); }
  |         NAME ival ';' { $$ = new_t(TREE_GLOBAL,new_s(NAME,$1),$2,NULL); }
  |         NAME '[' ival ']' ';' { $$ = new_t(TREE_GLOBAL_ARRAY,new_s(NAME,$1),$3,NULL); }
  |         NAME '[' ival ']' ival-list ';' { $$ = new_t(TREE_GLOBAL_ARRAY,new_s(NAME,$1),$3,$5); }
  |         NAME '(' name-list ')' '{' statement-list '}' { $$ = new_t(TREE_DEFUN,new_s(NAME,$1),$3,$6); }
  |         NAME '(' ')' '{' statement-list '}' { $$ = new_t(TREE_DEFUN,new_s(NAME,$1),NULL,$5); } 
  ;
 
ival-list: ival { $$ = add_list(NULL,$1); }
  |        ival ',' ival-list { $$ = new_l(TREE_LIST,$1,$3); }
  ;

name-list: NAME { $$ = add_list(NULL,new_s(NAME,$1)); }
  |        name-list ',' NAME { $$ = add_list($1,new_s(NAME,$3)); }
  ;

extrn-list: NAME { $$ = add_list(NULL,new_s(NAME,$1)); }
  |         NAME ',' extrn-list { $$ = new_l(TREE_LIST,new_s(NAME,$1),$3); }
  ;

ival: constant { $$ = $1; }
  |   NAME { $$ = new_s(NAME,$1);; }
  ;

statement: AUTO auto-defs ';' { $$ = $2; }
  |        EXTRN extrn-list ';' { $$ = new_t(EXTRN,$2,NULL,NULL); }
  |        NAME ':' { $$ = new_s(TREE_LABEL,$1); }
  |        CASE constant ':' { $$ = new_t(CASE,$2,NULL,NULL); }
  |        '{' statement-list '}' { $$ = $2; }
  |        IF '(' rvalue ')' statement { $$ = new_t(IF,$3,$5,NULL); }
  |        IF '(' rvalue ')' statement ELSE statement { $$ = new_t(IF,$3,$5,$7); }
  |        WHILE '(' rvalue ')' statement { $$ = new_t(WHILE,$3,$5,NULL); }
  |        SWITCH rvalue '{' statement-list '}' { $$ = new_t(SWITCH,$2,$4,NULL); }
  |        GOTO rvalue ';' { $$ = new_t(GOTO,$2,NULL,NULL); }
  |        RETURN ';' { $$ = new_t(RETURN,NULL,NULL,NULL); }
  |        RETURN '(' rvalue ')' ';' { $$ = new_t(RETURN,$3,NULL,NULL); }
  |        rvalue ';' { $$ = $1; }
  |        ';' { $$ = new_t(TREE_EMPTY,NULL,NULL,NULL); }
  ;

statement-list: /* empty */ { $$ = NULL; }
  |             statement { if ( $$->type == TREE_LIST ) $$ = $1; else $$ = add_list(NULL,$1); }
  |             statement-list statement {
                    if ( $2->type == TREE_LIST ) {
                        struct tree* p;
                        $$ = $1;
                        for ( p = $1; p->l.next; p = p->l.next );
                        p->l.next = $2;
                    } else $$ = add_list($1,$2);
                }
  ;

auto-defs: NAME { $$ = add_list(NULL,new_t(AUTO,new_s(NAME,$1),NULL,NULL)); }
  |        NAME constant { $$ = add_list(NULL,new_t(AUTO,new_s(NAME,$1),$2,NULL)); }
  |        auto-defs ',' NAME { $$ = add_list($1,new_t(AUTO,new_s(NAME,$3),NULL,NULL)); }
  |        auto-defs ',' NAME constant { $$ = add_list($1,new_t(AUTO,new_s(NAME,$3),$4,NULL)); }
  ;

rvalue: '(' rvalue ')' { $$ = $2; }
  |     lvalue assign rvalue {
            $2->t.t1 = $1;
            if ( $2->t.t2 ) {
                $2->t.t2->t.t1 = $1;
                $2->t.t2->t.t2 = $3;
            } else $2->t.t2 = $3;
            $$ = $2;
        }
  |     inc-dec lvalue { $1->t.t2 = $2; $$ = $1; }
  |     lvalue inc-dec { $2->t.t1 = $1; $$ = $2; }
  |     unary rvalue { $1->t.t1 = $2; $$ = $1; }
  |     rvalue '?' rvalue ':' rvalue { $$ = new_t(TREE_ELVIS,$1,$3,$5); }
  |     rvalue '+' rvalue { $$ = new_t('+',$1,$3,NULL); }
  |     rvalue '-' rvalue { $$ = new_t('-',$1,$3,NULL); }
  |     rvalue '*' rvalue { $$ = new_t('*',$1,$3,NULL); }
  |     rvalue '/' rvalue { $$ = new_t('/',$1,$3,NULL); }
  |     rvalue '%' rvalue { $$ = new_t('%',$1,$3,NULL); }
  |     rvalue '|' rvalue { $$ = new_t('|',$1,$3,NULL); }
  |     rvalue '&' rvalue { $$ = new_t('&',$1,$3,NULL); }
  |     rvalue EQ rvalue { $$ = new_t(EQ,$1,$3,NULL); }
  |     rvalue NE rvalue { $$ = new_t(NE,$1,$3,NULL); }
  |     rvalue LT rvalue { $$ = new_t(LT,$1,$3,NULL); }
  |     rvalue LE rvalue { $$ = new_t(LE,$1,$3,NULL); }
  |     rvalue GT rvalue { $$ = new_t(GT,$1,$3,NULL); }
  |     rvalue GE rvalue { $$ = new_t(GE,$1,$3,NULL); }
  |     rvalue LSHIFT rvalue { $$ = new_t(LSHIFT,$1,$3,NULL); }
  |     rvalue RSHIFT rvalue { $$ = new_t(RSHIFT,$1,$3,NULL); }
  |     rvalue '(' ')' { $$ = new_t(TREE_CALL,$1,NULL,NULL); }
  |     rvalue '(' rvalue-list ')' { $$ = new_t(TREE_CALL,$1,$3,NULL); }
  |     '*' rvalue { $$ = new_t(TREE_STORE,$2,NULL,NULL); }
  |     '&' lvalue { $$ = new_t(TREE_ADDR,$2,NULL,NULL); }
  |     lvalue { $$ = $1; }
  |     constant { $$ = $1; }
  ;

rvalue-list: rvalue { $$ = add_list(NULL,$1); }
  |          rvalue-list ',' rvalue { $$ = add_list($1,$3); } 
  ;

assign: ASSIGN {
          struct tree* opt;

          opt = NULL;
          if ( $1[0] && !strcmp($1,"==") ) opt = new_t(EQ,NULL,NULL,NULL);
          else if ( $1[0] && !strcmp($1,"!=") ) opt = new_t(NE,NULL,NULL,NULL);
          else if ( $1[0] && !strcmp($1,"<") ) opt = new_t(LT,NULL,NULL,NULL);
          else if ( $1[0] && !strcmp($1,"<=") ) opt = new_t(LE,NULL,NULL,NULL);
          else if ( $1[0] && !strcmp($1,">") ) opt = new_t(GT,NULL,NULL,NULL);
          else if ( $1[0] && !strcmp($1,">=") ) opt = new_t(GE,NULL,NULL,NULL);
          else if ( $1[0] && !strcmp($1,"<<") ) opt = new_t(LSHIFT,NULL,NULL,NULL);
          else if ( $1[0] && !strcmp($1,">>") ) opt = new_t(RSHIFT,NULL,NULL,NULL);
          else if ( $1[0] && strchr("|&+-%*/",$1[0]) ) opt = new_t($1[0],NULL,NULL,NULL);
          $$ = new_t(ASSIGN,NULL,opt,NULL);
      }
  ;

inc-dec: INC { $$ = new_t(INC,NULL,NULL,NULL); }
  |      DEC { $$ = new_t(DEC,NULL,NULL,NULL); }
  ;

unary: '-' { $$ = new_t('-',NULL,NULL,NULL); }
  |    '!' { $$ = new_t('!',NULL,NULL,NULL); }
  ;

/*
binary: '|' { $$ = new_t('|',NULL,NULL,NULL); }
  |     '&' { $$ = new_t('&',NULL,NULL,NULL); }
  |     EQ { $$ = new_t(EQ,NULL,NULL,NULL); }
  |     NE { $$ = new_t(NE,NULL,NULL,NULL); }
  |     LT { $$ = new_t(LT,NULL,NULL,NULL); }
  |     LE { $$ = new_t(LE,NULL,NULL,NULL); }
  |     GT { $$ = new_t(GT,NULL,NULL,NULL); }
  |     GE { $$ = new_t(GE,NULL,NULL,NULL); }
  |     LSHIFT { $$ = new_t(LSHIFT,NULL,NULL,NULL); }
  |     RSHIFT { $$ = new_t(RSHIFT,NULL,NULL,NULL); }
  |     '+' { $$ = new_t('+',NULL,NULL,NULL); }
  |     '-' { $$ = new_t('-',NULL,NULL,NULL); }
  |     '%' { $$ = new_t('%',NULL,NULL,NULL); }
  |     '*' { $$ = new_t('*',NULL,NULL,NULL); }
  |     '/' { $$ = new_t('/',NULL,NULL,NULL); }
  ;
  */

lvalue: NAME { $$ = new_s(NAME,$1); }
  |     rvalue '[' rvalue ']' { $$ = new_t(TREE_REF,$1,$3,NULL); }
  ;

constant: DIGIT { $$ = new_s(DIGIT,$1); }
  |       CHAR { $$ = new_s(CHAR,$1); }
  |       STRING { $$ = new_s(STRING,$1); }
  ;

%%

int yyerror(char const* str) {
    extern int yylineno;

    fprintf(stderr,"error:(%d) %s\n",yylineno,str);
}

int main(int argc,char* argv[]) {
    extern int yy_flex_debug;
    extern FILE* yyin;
    int r;

    init_type();

    yy_flex_debug = 0;
    yydebug = 0;
    debug = 1;

    if ( argc < 2 ) return 0;

    /* TODO llvmのソースにファイル名を設定 */
    yyin = fopen(argv[1],"r");
    return yyparse();
}
