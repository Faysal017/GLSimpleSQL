%{
    
#include <stdio.h>
#include <stdlib.h>
#include "sql.tab.h"

%}

%option yylineno
%option noyywrap
%option case-insensitive

ID          [A-Za-z_][A-Za-z0-9_]*
DIGIT       [0-9]
INT_CONST   -?{DIGIT}+
FLOAT_CONST -?{DIGIT}+"."{DIGIT}+
SQ_STRING    \'([^\\\']|\\.)*\'
DQ_STRING    \"([^\\\"]|\\.)*\"

%%

\n                          ;

    /* Gestion des éléments à ignorer */
"--".*                      { /* commentaire ligne à ignorer */ }
"/*"([^*]|\*+[^*/])*\*+"/"  { /* commentaire multi-lignes à ignorer */ }
[ \t\r]+                    { /* ignorer espaces, tabs et newlines */ }

    /* Mots-clés SQL */
"SELECT"                     return SELECT; 
"FROM"                       return FROM; 
"WHERE"                      return WHERE; 
"INSERT"                     return INSERT; 
"INTO"                       return INTO; 
"CREATE"                     return CREATE; 
"UPDATE"                     return UPDATE; 
"DELETE"                     return DELETE; 
"DROP"                       return DROP; 
"TABLE"                      return TABLE; 
"VALUES"                     return VALUES; 
"SET"                        return SET; 
"AND"                        return AND; 
"OR"                         return OR; 
"NOT"                        return NOT; 

    /* Types de données */
"INT"                        return INT_TYPE; 
"FLOAT"                      return FLOAT_TYPE; 
"VARCHAR""("{DIGIT}+")"      return VARCHAR_TYPE; 
"BOOL"                       return BOOL_TYPE; 

    /* Opérateurs */
"="                          return '='; 
"!="                         return NEQ; 
"<"                          return '<'; 
">"                          return '>'; 
"<="                         return LEQ; 
">="                         return GEQ; 

    /* Constantes */
{INT_CONST}                  return INT_CONST;
{FLOAT_CONST}                return FLOAT_CONST;
{SQ_STRING}                  return STRING; 
{DQ_STRING}                  return STRING; 
"TRUE"                       return TRUE_BOOL; 
"FALSE"                      return FALSE_BOOL; 

    /* Symboles */
"("                          return '('; 
")"                          return ')'; 
","                          return ','; 
";"                          return ';'; 
"*"                          return '*'; 

    /* Identificateurs */
{ID}                         { yylval.str = strdup(yytext); return IDENTIFIER; } 

    /* Gestion des erreurs lexicales */
.                            { 
                                printf("ERREUR LEXICALE line %d: \n", yylineno);
                                printf("\tCaractere inconnu \"%s\"\n\n", yytext);
                                return YYerror;
                             }

%%