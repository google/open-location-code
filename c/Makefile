all: example olc_test

CFLAGS += -std=c99
CFLAGS += -Wall
# CFLAGS += -Wextra
CFLAGS += -Wno-comment

ALL_FLAGS += -g

%.o : %.c
	$(CC) -c $(ALL_FLAGS) $(CFLAGS) $(CPPFLAGS) -o $@ $<

example: olc.o example.o
	$(CC) $(ALL_FLAGS) $^ -o $@

olc_test: olc.o olc_test.o
	$(CC) $(ALL_FLAGS) $^ -o $@

clean:
	rm -f *.o crash-* slow-unit-*
	rm -fr *.dSYM
	rm -f example
	rm -f olc_test

test: olc_test
	./olc_test 2>/dev/null
