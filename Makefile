TARGET = sql

FLEX_SRC = src/sql.l
BISON_SRC = src/sql.y
AST_SRC = src/ast.c
MAIN = main.c

FLEX_OUT = src/lex.yy.c
BISON_C_OUT = src/sql.tab.c
BISON_H_OUT = src/sql.tab.h

all: $(TARGET)

$(TARGET): $(FLEX_OUT) $(BISON_C_OUT) $(AST_SRC)
	gcc -o $(TARGET) $(MAIN) $(FLEX_OUT) $(BISON_C_OUT) $(AST_SRC)

$(FLEX_OUT): $(FLEX_SRC)
	flex -o $(FLEX_OUT) $(FLEX_SRC)

$(BISON_C_OUT) $(BISON_H_OUT): $(BISON_SRC)
	bison -d -o $(BISON_C_OUT) $(BISON_SRC)

test: $(TARGET)
	.\$(TARGET) tests/baseTests.txt

clean:
	rm -f $(FLEX_OUT) $(BISON_C_OUT) $(BISON_H_OUT) $(TARGET)

.PHONY: clean test