#ifndef _AST_H_
#define _AST_H_

typedef enum {
    INT,
    FLOAT,
    TEXT,
    BOOL
}valueType;

typedef struct champType {
    valueType type;
    struct champType *next;
}champType;

typedef struct column {
    char *name;
    valueType type;
    struct column *next;
}column;

typedef struct table {
    char *name;
    column *columns;
    int nbrCol;
    struct table *next;
}table;

extern table *tables;

table *createTable(char *name, column *columns, int nbrCol);
int addTable(table *newTable);
table *findTable(char *name);
int dropTable(char *name);

column *createColumn(char *name, valueType type);
int addColumn(column **columns, column *newColumns);
int is_all_columns_in_table(table *tab, column *columns);
column *appendColumns(column *col1, column *col2);
void setColumnType(table *tab, column *columns);
void clearColumns(column *columns);


champType *create_type_node(valueType type);
int addTypeNode(champType **champTypes, champType *newType);
int isTypesCompatible(column *columns, champType *types);
void type(valueType type);
champType *appendTypes(champType *type1, champType *type2);
void clearTypes(champType *champTypes);


int isWhereVerified(column *columns, champType *types);
void clearAll();

#endif