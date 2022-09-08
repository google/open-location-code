all: run

RUNS = 1000000

C_MAIN = bm-c.c
CC_MAIN = bm-cpp.cc

LD_FLAGS += -lm

# C compilation
C_FLAGS += -Wall
C_FLAGS += -Wno-comment
C_FLAGS += -I../../c
# C_FLAGS += -Wextra
# C_FLAGS += -DOLC_CHECK_RESULTS

C_ALL_FLAGS += -std=c99
# C_ALL_FLAGS += -g

# C++ compilation
CC_FLAGS += -Wall
CC_FLAGS += -Wno-comment
CC_FLAGS += -I../../cpp
# CC_FLAGS += -Wextra
# CC_FLAGS += -DOLC_CHECK_RESULTS

CC_ALL_FLAGS += -std=c++11
CC_ALL_FLAGS += -pthread
# CC_ALL_FLAGS += -g

# everything below here should be taken care of automatically
# no need to edit these lines, except to add new binary targets

LIB_NAME = olc

C_OBJ = $(C_MAIN:.c=.o)
C_EXE = $(C_MAIN:.c=)

CC_OBJ = $(CC_MAIN:.cc=.o)
CC_EXE = $(CC_MAIN:.cc=)

%.o : %.c
	cc -c $(C_ALL_FLAGS) $(C_FLAGS) -o $@ $<

%.o : %.cc
	c++ -c $(CC_ALL_FLAGS) $(CC_FLAGS) -o $@ $<

$(C_EXE): $(C_OBJ)
	cc $(C_ALL_FLAGS) -o $(C_EXE) $(LD_FLAGS) $(C_OBJ) -L../../c -l$(LIB_NAME)

$(CC_EXE): $(CC_OBJ)
	c++ $(CC_ALL_FLAGS) -o $(CC_EXE) $(LD_FLAGS) $(CC_OBJ) -L../../cpp -l$(LIB_NAME)

run: bm-c bm-cpp
	./$(C_EXE) $(RUNS)
	./$(CC_EXE) $(RUNS)

clean:
	rm -f crash-* slow-unit-* *.dSYM
	rm -f $(C_OBJ) $(CC_OBJ)
	rm -f $(C_EXE) $(CC_EXE)
