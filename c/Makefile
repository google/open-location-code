all: example test_csv

CPPFLAGS += -DMEM_CHECK=1

CFLAGS += -std=c99
CFLAGS += -Wall
# CFLAGS += -Wextra
CFLAGS += -Wno-comment

ALL_FLAGS += -g

%.o : %.c
	$(CC) -c $(ALL_FLAGS) $(CFLAGS) $(CPPFLAGS) -o $@ $<

example: olc.o example.o
	$(CC) $(ALL_FLAGS) $^ -o $@

test_csv: olc.o test_csv.o
	$(CC) $(ALL_FLAGS) $^ -o $@

clean:
	rm -f *.o crash-* slow-unit-*
	rm -fr *.dSYM
	rm -f example
	rm -f test_csv
