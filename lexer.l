%{
#define _POSIX_SOURCE
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Define strdup if not available */
#ifndef strdup
char* strdup(const char* s) {
    size_t len = strlen(s) + 1;
    char* new_str = malloc(len);
    if (new_str) {
        memcpy(new_str, s, len);
    }
    return new_str;
}
#endif
%}

%%
[ \t\r\n]                {}
[0-9]+                   { yylval = atoi(yytext); return NUMBER; }

"start"                  { return START; }
"done"                   { return DONE; }
"output"                 { return OUTPUT; }
"take"                   { return TAKE; }
"if"                     { return IF; }
"else"                   { return ELSE; }
"iterate"                { return ITERATE; }
"from"                   { return FROM; }
"to"                     { return TO; }
"by"                     { return BY; }
"define"                 { return DEFINE; }
"call"                   { return CALL; }

"=="                     { return EQ; }
"!="                     { return NEQ; }
">"                      { return GT; }
"<"                      { return LT; }
">="                     { return GTE; }
"<="                     { return LTE; }

"+"                      { return PLUS; }
"-"                      { return MINUS; }
"*"                      { return TIMES; }
"/"                      { return DIVIDE; }
"%"                      { return MOD; }
"="                      { return ASSIGN; }

"{"                      { return LBRACE; }
"}"                      { return RBRACE; }
"("                      { return LPAREN; }
")"                      { return RPAREN; }
","                      { return COMMA; }

[a-zA-Z][a-zA-Z0-9_]*   { 
                           /* For variable names, just store the first character as the identifier */
                           /* This simplifies variable handling for RUSH */
                           yylval = (long)(yytext[0]); 
                           
                           return IDENTIFIER; 
                         }

\"[^\"]*\"              { 
                           /* For strings, we need to allocate a copy */
                           char* str = strdup(yytext);
                           if (!str) {
                               //fprintf(stderr, "Memory allocation failed for string\n");
                               exit(1);
                           }
                           yylval = (long)str;
                           return STRING; 
                         }

"/*"([^*]|"*"+[^*/])*"*"+"/"  { /* Skip comments */ }

.                        { return yytext[0]; }

%%

int yywrap(void) {
    return 1;
}