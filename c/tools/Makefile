all: lug

C_FLAGS += -Wall
# C_FLAGS += -Wextra
C_FLAGS += -Wno-comment

ALL_FLAGS += -std=c99
# ALL_FLAGS += -g

%.o : %.c
	$(CC) -c $(ALL_FLAGS) $(C_FLAGS) $(CPP_FLAGS) -o $@ $<

lug: lug.o $(LIB_A_FILE)
	$(CC) $(ALL_FLAGS) -o $@ lug.o $(LD_FLAGS)

clean:
	rm -f crash-* slow-unit-* *.dSYM gmon.out
	rm -f lug.o
	rm -f lug
