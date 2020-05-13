%{
#include <stdio.h>
#include "b.tab.h"

%}

%option yylineno
%x COMMENT

%%
\/\* BEGIN(COMMENT);
<COMMENT>\n ;
<COMMENT>. ;
<COMMENT>\*\/ BEGIN(INITIAL);
auto return AUTO;
extrn return EXTRN;
if return IF;
else return ELSE;
goto return GOTO;
switch return SWITCH;
case return CASE;
return return RETURN;
while return WHILE;
\<\< return LSHIFT;
\>\> return RSHIFT;
\+\+ return INC;
\-\- return DEC;
== return EQ;
!= return NE;
\<= return LE;
\< return LT;
\>= return GE;
\> return GT;
=\| { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=\& { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=== { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=!= { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=< { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=<= { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=> { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=>= { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=<< { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=>> { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=\+ { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=\- { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=\% { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=\* { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
=\/ { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
= { strcpy(yylval.s,&yytext[1]); return ASSIGN; }
[A-Za-z_][A-Za-z_0-9]* { strcpy(yylval.s,yytext); return NAME; }
'[^']+' { strcpy(yylval.s,&yytext[1]);yylval.s[strlen(yylval.s)-1] = '\0'; return CHAR; }
\"[^"]*\" { strcpy(yylval.s,&yytext[1]); yylval.s[strlen(yylval.s)-1] = '\0'; return STRING; }
[0-9]+ { strcpy(yylval.s,yytext); return DIGIT; }
[ \t\r]+ ;
\n ;
. { strcpy(yylval.s,yytext);return yytext[0]; }

%%

int yywrap() {
    return 1;
}
