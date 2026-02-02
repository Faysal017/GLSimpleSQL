%code requires {
    #include "ast.h"
}

%{

#include <stdio.h>

extern int yylex();
void yyerror(const char *msg);

extern int yylineno;

%}

%define parse.error detailed

%union {
    char *str;

    struct { 
                column *col;
                int nb; 
        } columnInfo;

    struct { 
                champType *types; 
                int nb; 
        } valeurInfo;

    struct { 
                column *col;
                champType *types;
                int condCount;
                int lopCount; 
        } condInfo;

    struct { 
                column *col; 
                champType *types; 
                int assignCount;
        } assignInfo;

    valueType type;
}

%token SELECT CREATE INSERT UPDATE DELETE DROP
%token INTO TABLE VALUES FROM WHERE SET  
%token LEQ GEQ NEQ
%token INT_TYPE FLOAT_TYPE VARCHAR_TYPE BOOL_TYPE
%token INT_CONST FLOAT_CONST STRING TRUE_BOOL FALSE_BOOL
%token <str> IDENTIFIER

%type <columnInfo> liste_def_champs liste_champs_insert liste_champs_select 
%type <columnInfo> def_champ validList
%type <condInfo> opt_where conditions condition
%type <assignInfo> affectations affectation
%type <valeurInfo> liste_valeur 
%type <str> nom_champ nom_table
%type <type> type_donnee valeur

%right NOT
%left AND OR

%start program

%%

program:
          requete ';'
        | requete ';' program
        ;

requete:
          create_table
        | insert_into
        | select    
        | update
        | delete
        | drop_table
        ;

create_table:
          CREATE TABLE nom_table '(' liste_def_champs ')'           
          {
                if(findTable($3) != NULL) {
                        printf("ERREUR SEMANTIQUE ligne %d:\n", yylineno);
                        printf("\tvous tentez de creer une table \"%s\" qui existe deja.\n\n", $3);
                        clearColumns($5.col);
                        free($3);
                } else {
                        addTable(createTable($3, $5.col, $5.nb));
                        printf("Requete \"CREATE TABLE\" analysee: \n");
                        printf("\t- La nouvelle table: %s\n", $3);
                        printf("\t- Nombre de champs: %d ( ", $5.nb);
                        column *curr = $5.col;
                        while(curr != NULL) {
                                printf("%s, ", curr->name);
                                curr = curr->next;
                        }
                        printf("\b\b )\n");//\n\n
                }
                printf("========================================================================\n\n");
          }
        ;

insert_into:
          INSERT INTO nom_table liste_champs_insert VALUES '(' liste_valeur ')'
          {
                table *tab = findTable($3);
                if(tab == NULL) {
                        printf("ERREUR SEMANTIQUE ligne %d:\n", yylineno);
                        printf("\tvous essayez d'inserer des donnees dans une table \"%s\" inexistante.\n\n", $3);
                } else {
                        column *selectCols;
                        int nbrCol;
                        if($4.col == NULL) {
                                // No column list → use all table columns
                                selectCols = tab->columns;
                                nbrCol = tab->nbrCol; 
                        } else {
                                selectCols = $4.col;
                                nbrCol = $4.nb;
                                setColumnType(tab, selectCols);
                        }
                        if(nbrCol < $7.nb) {
                                printf("ERREUR SEMANTIQUE ligne %d:\n", yylineno);
                                printf("\tINSERT INTO %s: Le nombre de colonnes selectionnees %d ne correspond pas au nombre de valeurs fournies %d pour l'instruction INSERT INTO.\n\n", tab->name, nbrCol, $7.nb);
                        } else {  
                                //if $4.col is NULL means that all columns are selected so the function will return 0
                                if(!is_all_columns_in_table(tab, $4.col)) {
                                        if(!isTypesCompatible(selectCols, $7.types)) {
                                                printf("Requete \"INSERT INTO\" analysee: \n");
                                                printf("\t- Table: %s\n", tab->name);
                                                printf("\t- Nombre de valeurs a inserer: %d dans ", $7.nb);
                                                if(!$4.col) {
                                                        if(nbrCol == $7.nb)
                                                                printf("toutes les %d champs de la table.\n", nbrCol);
                                                        else
                                                                printf("les %d premiere champs de la table.\n", $7.nb);
                                                } else {
                                                        printf("les %d champs selectionner.\n", nbrCol);
                                                }
                                                printf("\t- la correspondance nombre de champs/valeurs est verifiee\n\n");
                                        }
                                }       
                        }
                }
                printf("========================================================================\n\n");       
                clearColumns($4.col);
                clearTypes($7.types);
                free($3);
          }                                                                                                       
        ;

select:
          SELECT liste_champs_select FROM nom_table opt_where   
          {
                table *tab = findTable($4);
                if(tab == NULL) {
                        printf("ERREUR SEMANTIQUE ligne %d:\n", yylineno);
                        printf("\tLa table \"%s\" n'existe pas.\n\n", $4); 
                } else {
                        if(!is_all_columns_in_table(tab, $2.col) && !is_all_columns_in_table(tab, $5.col)) {
                                setColumnType(tab, $5.col);
                                if(!isWhereVerified($5.col, $5.types)) {
                                        int nb = ($2.col) ? $2.nb : tab->nbrCol;
                                        column *curr = ($2.col) ? $2.col : tab->columns;
                                        printf("Requete \"SELECT\" analysee: \n");
                                        printf("\t- Table :%s\n", tab->name);
                                        printf("\t- Nombre de champs: %d ( ", nb);
                                        while(curr != NULL) {
                                                printf("%s, ", curr->name);
                                                curr = curr->next;
                                        }
                                        printf("\b\b )\n");
                                        printf("\t- Clause WHERE: ");
                                        if($5.condCount != 0) {
                                                printf("OUI\n");
                                                printf("\t- Nombre de conditions: %d\n", $5.condCount);
                                                printf("\t- Operateur logiques: %d\n\n", $5.lopCount);
                                        } else {
                                                printf("NON\n\n");
                                        }
                                }
                        }
                }
                printf("========================================================================\n\n");
                free($4);
                clearColumns($2.col);
                clearColumns($5.col);
                clearTypes($5.types);
          }
        ;

update:
          UPDATE nom_table SET affectations opt_where
          {
                table *tab = findTable($2);
                if(tab == NULL) {
                        printf("ERREUR SEMANTIQUE ligne %d:\n", yylineno);
                        printf("\tvous essayez de modifier les donnees d'une table \"%s\" inexistante.\n\n", $2); 
                } else {
                        setColumnType(tab, $4.col);
                        if(!is_all_columns_in_table(tab, $4.col) && !is_all_columns_in_table(tab, $5.col)) {
                                if(!isTypesCompatible($4.col, $4.types)) {
                                        if(!isWhereVerified($5.col, $5.types)) {
                                                printf("Requete \"UPDATE\" analysee: \n");
                                                printf("\t- Table: %s\n", $2);
                                                printf("\t- Nombre de champs a modifier: %d ( ", $4.assignCount);
                                                column *curr = $4.col;
                                                while(curr != NULL) {
                                                        printf("%s, ", curr->name);
                                                        curr = curr->next;
                                                }
                                                printf("\b\b )\n");
                                                printf("\t- Clause WHERE: ");
                                                if($5.condCount != 0) {
                                                        printf("OUI\n");
                                                        printf("\t  Ainsi, tous les enregistrements des champs selectionner satisfaisant la condition seront mis a jour.\n");
                                                        printf("\t- Nombre de conditions: %d\n", $5.condCount);
                                                        printf("\t- Operateur logiques: %d\n\n", $5.lopCount);
                                                } else {
                                                        printf("NON\n");
                                                        printf("\t  Alors, tous les enregistrements des champs selectionner seront mis a jour.\n\n");
                                                }
                                        }
                                }
                        }
                }
                printf("========================================================================\n\n");
                free($2);
                clearColumns($4.col);
                clearTypes($4.types);
                clearColumns($5.col);
                clearTypes($5.types);
          }
        ;

delete:
          DELETE FROM nom_table opt_where
        {
                table *tab = findTable($3);
                if(tab == NULL) {
                        printf("ERREUR SEMANTIQUE ligne %d:\n", yylineno);
                        printf("\tvous essayez de supprimer les donnees dans une table \"%s\" inexistante.\n\n", $3);
                } else {
                        if(!isWhereVerified($4.col, $4.types)) {
                                printf("Requete \"DELETE\" analysee: \n");
                                printf("\t- Table: %s\n", $3);
                                printf("\t- Clause WHERE: ");
                                if($4.condCount != 0) {
                                        printf("OUI\n");
                                        printf("\t  Ainsi, toutes les enregistrement qui remplissent la condition seront supprimees.\n");
                                        printf("\t- Nombre de conditions: %d\n", $4.condCount);
                                        printf("\t- Operateur logiques: %d\n\n", $4.lopCount);
                                } else {
                                        printf("NON\n");
                                        printf("\t  Alors, toutes les enregistrement de la table seront supprimees.\n\n");
                                }
                        }
                }
                printf("========================================================================\n\n");
                free($3);
                clearColumns($4.col);
                clearTypes($4.types);
        }
        ;

drop_table:
          DROP TABLE nom_table 
        {        
                if(dropTable($3)) {
                        printf("Requete \"DROP TABLE\" analysee: \n");
                        printf("\t- La table %s a bien ete supprimee!\n\n", $3);
                } else {
                        printf("ERREUR SEMANTIQUE ligne %d:\n", yylineno);
                        printf("\tvous essayez de supprimer une table \"%s\" inexistante.\n\n", $3);
                }
                printf("========================================================================\n\n");
                free($3);
        }
        ;

opt_where:
          %empty
          {
                $$.condCount = 0;
                $$.lopCount = 0;
                $$.col = NULL;
                $$.types = NULL;
          }
        | WHERE conditions
          {
                $$.col = $2.col;
                $$.types = $2.types;
                $$.condCount = $2.condCount;
                $$.lopCount = $2.lopCount;
          }
        ;

affectations:
          affectation
          {
                $$.col = $1.col;
                $$.types = $1.types;
                $$.assignCount = 1;
          }
        | affectation ',' affectations
          {
                addColumn(&($3.col), $1.col);
                addTypeNode(&($3.types), $1.types);
                $$.col = $3.col;
                $$.types = $3.types;
                $$.assignCount = 1 + $3.assignCount;
          }
        ;

affectation:
          nom_champ '=' valeur
          {
                $$.col = createColumn($1, 0);
                $$.types = create_type_node($3);
          }
        ;

liste_def_champs:
          def_champ                         { 
                                                $$.col = $1.col;
                                                $$.nb = 1;
                                            }
        | def_champ ',' liste_def_champs    { 
                                                addColumn(&($3.col), $1.col);
                                                $$.col = $3.col;
                                                $$.nb = 1 + $3.nb;
                                            }
        ;

def_champ:
          nom_champ type_donnee             { 
                                                $$.col = createColumn($1, $2);
                                                $$.nb = 0;
                                            }
        ;

liste_champs_select:
          '*'   
          { 
                $$.col = NULL;
          }
        | validList 
          {
                $$.col = $1.col;
                $$.nb = $1.nb;
          }
        | inValidList 
          {
                printf("ERREUR SYNTAXIQUE line %d:\n", yylineno);
                printf("\tUtilisation invalide de *\n\n");
                return 1;
          }
        ;

liste_champs_insert:
          %empty
          {
                $$.col = NULL;
                $$.nb = 0;
          }
        | '(' validList ')'
          {
                $$.col = $2.col;
                $$.nb = $2.nb;
          }
        ;

validList:
          nom_champ     
          {
                $$.col = createColumn($1, 0);
                $$.nb = 1; 
          }
        | nom_champ ',' validList
          { 
                addColumn(&($3.col), createColumn($1, 0)); 
                $$.col = $3.col; 
                $$.nb = 1 + $3.nb; 
          }
        ;

inValidList:
          '*' ',' nom_champ
        | nom_champ ',' '*'
        | inValidList ',' nom_champ
        ;

nom_table:
          IDENTIFIER     { $$ = $1; }
        ;

nom_champ:
          IDENTIFIER     { $$ = $1; }
        ;

type_donnee:
          INT_TYPE       { $$ = INT; }
        | FLOAT_TYPE     { $$ = FLOAT; }
        | VARCHAR_TYPE   { $$ = TEXT; }
        | BOOL_TYPE      { $$ = BOOL; }
        ;

liste_valeur:
          valeur         
          {
                $$.types = create_type_node($1); 
                $$.nb = 1; 
          }
        | valeur ',' liste_valeur      
          { 
                addTypeNode(&($3.types), create_type_node($1));
                $$.types = $3.types;
                $$.nb = 1 + $3.nb; 
          }
        ;
               
valeur:
          INT_CONST     { $$ = INT;   }
        | FLOAT_CONST   { $$ = FLOAT; }
        | STRING        { $$ = TEXT;  }
        | TRUE_BOOL     { $$ = BOOL;  }
        | FALSE_BOOL    { $$ = BOOL;  }
        ;

conditions:
          condition
          {
                $$.col = $1.col;
                $$.types = $1.types;
                $$.condCount = 1;
                $$.lopCount = 0;
          }
        | conditions AND conditions
          {
                $$.col = appendColumns($1.col, $3.col);
                $$.types = appendTypes($1.types, $3.types);
                $$.condCount = $1.condCount + $3.condCount;
                $$.lopCount = 1 + $1.lopCount + $3.lopCount;
          }
        | conditions OR conditions
          {
                $$.col = appendColumns($1.col, $3.col);
                $$.types = appendTypes($1.types, $3.types);
                $$.condCount = $1.condCount + $3.condCount;
                $$.lopCount = 1 + $1.lopCount + $3.lopCount;
          }
        | NOT conditions
          {
                $$.col = $2.col;
                $$.types = $2.types;
                $$.condCount = $2.condCount;
                $$.lopCount = 1 + $2.lopCount;
          }
        | '(' conditions ')'
          {
                $$.col = $2.col;
                $$.types = $2.types;
                $$.condCount = $2.condCount;
                $$.lopCount = $2.lopCount;
          }
        ;

condition:
          nom_champ operator valeur
        {
                $$.col = createColumn($1, 0);
                $$.types = create_type_node($3);
        }

operator:
          '='
        |  NEQ
        |  '<'
        |  '>'
        |  LEQ
        |  GEQ
        ;

%%

void yyerror(const char *msg) {
    printf("%s line %d\n\n", msg, yylineno);
}