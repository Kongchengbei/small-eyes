CC ?= gcc
FLEX ?= flex
BISON ?= bison
PKG_CONFIG ?= pkg-config

ROOT := ../..
OUT := $(abspath $(ROOT)/build/kconfig)
OBJ := $(OUT)/obj
CPPFLAGS += -I. -I$(OBJ) -Ilxdialog $(shell $(PKG_CONFIG) --cflags ncursesw)
CFLAGS += -DYYDEBUG -std=gnu11
CURSES_LIBS := $(shell $(PKG_CONFIG) --libs ncursesw)

COMMON_OBJS := $(addprefix $(OBJ)/,confdata.o expr.o preprocess.o symbol.o util.o \
	lexer.lex.o parser.tab.o)
LXDIALOG_OBJS := $(patsubst lxdialog/%.c,$(OBJ)/lxdialog_%.o,$(wildcard lxdialog/*.c))

.PHONY: all clean
all: $(OUT)/conf $(OUT)/mconf

$(OBJ) $(OBJ)/lxdialog:
	mkdir -p "$@"

$(OBJ)/%.o: %.c | $(OBJ)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c "$<" -o "$@"

$(OBJ)/lxdialog_%.o: lxdialog/%.c | $(OBJ)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c "$<" -o "$@"

$(OBJ)/parser.stamp: parser.y | $(OBJ)
	$(BISON) -v "$<" --defines=$(OBJ)/parser.tab.h -o $(OBJ)/parser.tab.c
	touch "$@"

$(OBJ)/parser.tab.c $(OBJ)/parser.tab.h: $(OBJ)/parser.stamp
	@test -f "$@"

$(OBJ)/lexer.lex.c: lexer.l $(OBJ)/parser.tab.h
	$(FLEX) -o "$@" "$<"

$(OBJ)/lexer.lex.o: $(OBJ)/lexer.lex.c $(OBJ)/parser.tab.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c "$(OBJ)/lexer.lex.c" -o "$@"

$(OBJ)/parser.tab.o: $(OBJ)/parser.tab.c $(OBJ)/parser.tab.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c "$(OBJ)/parser.tab.c" -o "$@"

$(OUT)/conf: $(COMMON_OBJS) $(OBJ)/conf.o | $(OUT)
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o "$@"

$(OUT)/mconf: $(COMMON_OBJS) $(OBJ)/mconf.o $(LXDIALOG_OBJS) | $(OUT)
	$(CC) $(LDFLAGS) $^ $(CURSES_LIBS) $(LDLIBS) -o "$@"

$(OUT):
	mkdir -p "$@"

clean:
	rm -rf "$(OUT)"
