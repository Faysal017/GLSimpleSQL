#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"

table *tables = NULL;
extern int yylineno;

table *createTable(char *name, column *columns, int nbrCol) {
    table *newTable = (table*)malloc(sizeof(table));
    if(!newTable)
        return NULL;
    newTable->name = name;
    newTable->columns = columns;
    newTable->nbrCol = nbrCol;
    newTable->next = NULL;
    return newTable;
}

int addTable(table *newTable) {
    if(!newTable)
        return 0;
    newTable->next = tables;
    tables = newTable;
    return 1;
}

table *findTable(char *name) {
    table *curr = tables;
    while(curr != NULL) {
        if(strcmp(curr->name, name) == 0)
            return curr;
        curr = curr->next;
    }
    return NULL;
}

int dropTable(char *name) {
    table dummy;
    table *prev, *curr;
    column *next_column;
    dummy.next = tables;
    curr = tables;
    prev = &dummy;
    while(curr && strcmp(curr->name, name)) {
        prev = curr;
        curr = curr->next;
    }
    if(curr == NULL) {
        return 0;
    }
    prev->next = curr->next;
    tables = dummy.next;
    free(curr->name);
    curr->name = NULL;
    while(curr->columns) {
        next_column = curr->columns->next;
        free(curr->columns->name);
        curr->columns->name = NULL;
        free(curr->columns);
        curr->columns = next_column;
    }
    free(curr);
    return 1;
}


column *createColumn(char *name, valueType type) {
    column *newColumn = (column*)malloc(sizeof(column));
    if(!newColumn)
        return NULL;
    newColumn->name = name;
    newColumn->type = type;
    newColumn->next = NULL;
    return newColumn;
}

int addColumn(column **columns, column *newColumn) {
    if(!newColumn)
        return 0;
    newColumn->next = *columns;
    *columns = newColumn;
    return 1; 
}

int is_all_columns_in_table(table *tab, column *columns) {
    column *curr_column;
    int symanticERROR = 0;
    while(columns != NULL) {
        curr_column = tab->columns;
        while(curr_column != NULL) {
            if(strcmp(curr_column->name, columns->name) == 0)
                break;
            curr_column = curr_column->next;
        }
        if(curr_column == NULL) {
            printf("ERREUR SEMANTIQUE ligne %d:\n", yylineno);
            printf("\tLe champ \"%s\" n'existe pas dans la table \"%s\".\n\n", columns->name, tab->name);
            symanticERROR = 1;
        }
        columns = columns->next;
    }
    return symanticERROR;
}

column *appendColumns(column *col1, column *col2) {
    if(!col1) return col2;
    column *curr = col1;
    while(curr->next != NULL)
        curr = curr->next;
    curr->next = col2;
    return col1;
}

void setColumnType(table *tab, column *columns) {
    column *curr_column;
    while(columns != NULL) {
        curr_column = tab->columns;
        while(curr_column != NULL) {
            if(strcmp(curr_column->name, columns->name) == 0) {
                columns->type = curr_column->type;
                break;
            }
            curr_column = curr_column->next;
        }
        columns = columns->next;
    }
}

void clearColumns(column *columns) {
    column *next;
    while(columns != NULL) {
        next = columns->next;
        free(columns->name);
        columns->name = NULL;
        free(columns);
        columns = next;
    }
    columns = NULL;
}


champType *create_type_node(valueType type) {
    champType *newTypeNode = (champType*)malloc(sizeof(champType));
    if(!newTypeNode)
        return NULL;
    newTypeNode->type = type;
    newTypeNode->next = NULL;
    return newTypeNode;
}

int addTypeNode(champType **champTypes, champType *newType) {
    if(!(*champTypes) || !newType)
        return 0;
    newType->next = *champTypes;
    *champTypes = newType;
    return 1;
}

int isTypesCompatible(column *columns, champType *types) {
    int symanticERROR = 0;
    while(types != NULL) {
        if(columns->type != types->type) {
            printf("ERREUR SEMANTIQUE ligne %d:\n", yylineno);
            printf("\tLe champ \"%s\" est de type ", columns->name);
            type(columns->type);
            printf(", mais vous essayez de lui affecter un type ");
            type(types->type);
            printf("\n\n");
            symanticERROR = 1;
        }
        columns = columns->next;
        types = types->next;
    }
    return symanticERROR;
}

void type(valueType type) {
    switch (type) {
        case INT:
            printf("INT");
            break;
        case FLOAT:
            printf("FLOAT");
            break;
        case TEXT:
            printf("VARCHAR");
            break;
        case BOOL:
            printf("BOOL");
    }
}

champType *appendTypes(champType *type1, champType *type2) {
    if(!type1) return type2;
    champType *curr = type1;
    while(curr->next != NULL)
        curr = curr->next;
    curr->next = type2;
    return type1;
}

void clearTypes(champType *champTypes) {
    champType *next;
    while(champTypes) {
        next = champTypes->next;
        free(champTypes);
        champTypes = next;
    }
}


int isWhereVerified(column *columns, champType *types) {
    int symanticERROR = 0;
    while(columns != NULL) {
        if(columns->type != types->type) {
            printf("ERREUR SEMANTIQUE ligne %d:\n", yylineno);
            printf("\tDans le Clause WHERE: ");
            printf("Le champ \"%s\" est de type ", columns->name);
            type(columns->type);
            printf(", mais vous essayez de lui comparer avec un type ");
            type(types->type);
            printf("\n\n");
            symanticERROR = 1;
        }
        columns = columns->next;
        types = types->next;
    }
    return symanticERROR;
}

void clearAll() {
    table *next_table;
    column *next_column;
    while(tables) {
        next_table = tables->next;
        free(tables->name);
        while(tables->columns) {
            next_column = tables->columns->next;
            free(tables->columns->name);
            free(tables->columns);
            tables->columns = next_column;
        }
        free(tables);
        tables = next_table;
    }
}