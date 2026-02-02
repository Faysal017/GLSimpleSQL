#include <stdio.h>
#include "src\sql.tab.h"

extern FILE *yyin;

int main(int argc, char *argv[]) {
    if(argc > 1) {
        yyin = fopen(argv[1], "r");
        if(!yyin) {
            printf("Erreur lors de l'ouverture du fichier: %s\n", argv[1]);
            return 1;
        }
    } else {
        printf("Entrez vos requetes (Ctrl+Z pour terminer)\n\n");
    }

    yyparse();
    clearAll();

    return 0;
}