all: lib

LIB_NAME = olc

LIB_C_FILES = \
	olc.c  \

C_FLAGS += -Wall
# C_FLAGS += -Wextra
C_FLAGS += -Wno-comment

LD_FLAGS += -lm

ALL_FLAGS += -std=c99
ALL_FLAGS += -g

# everything below here should be taken care of automatically
# no need to edit these lines, except to add new binary targets

LIB_H_FILES = $(LIB_C_FILES:.c=.h)
LIB_OBJ_FILES = $(LIB_C_FILES:.c=.o)
LIB_A_FILE = lib$(LIB_NAME).a

%.o : %.c
	$(CC) -c $(ALL_FLAGS) $(C_FLAGS) $(CPP_FLAGS) $(LD_FLAGS) -o $@ $<

$(LIB_A_FILE): $(LIB_OBJ_FILES)
	ar rvs $@ $^

example: example.o $(LIB_A_FILE)
	$(CC) $(ALL_FLAGS) -o $@ example.o $(LD_FLAGS) -L. -l$(LIB_NAME)

olc_test: olc_test.o $(LIB_A_FILE)
	$(CC) $(ALL_FLAGS) -o $@ olc_test.o $(LD_FLAGS) -L. -l$(LIB_NAME)

lib: $(LIB_A_FILE)

test: olc_test
	./olc_test 2>&1 | egrep -v '^OK '

clean:
	rm -f crash-* slow-unit-* *.dSYM
	rm -f $(LIB_OBJ_FILES) $(LIB_A_FILE)
	rm -f example.o olc_test.o
	rm -f example olc_test
	rm -f olc_test

install: libolc.a olc.h
	mkdir -p /usr/local/lib
	cp $(LIB_A_FILE) /usr/local/lib
	mkdir -p /usr/local/include
	cp $(LIB_H_FILES) /usr/local/include
