#ifndef TESTS_H_
#define TESTS_H_

// Poor man's testing macros

#define TEST(group, name) static void test_ ## group ## _ ## name (void)

#define EXPECT_BINOP(op, a, b) \
    do { \
        int ok = (a) op (b); \
        fprintf(stderr, "%-3.3s [%s] %s [%s]\n", ok ? "OK" : "BAD", #a, #op, #b); \
        /* if (!ok) { abort(); } */ \
    } while (0)

#define EXPECT_EQ(a, b) EXPECT_BINOP(==, a, b)
#define EXPECT_NE(a, b) EXPECT_BINOP(!=, a, b)
#define EXPECT_LT(a, b) EXPECT_BINOP(< , a, b)
#define EXPECT_LE(a, b) EXPECT_BINOP(<=, a, b)
#define EXPECT_GT(a, b) EXPECT_BINOP(> , a, b)
#define EXPECT_GE(a, b) EXPECT_BINOP(>=, a, b)

#endif
