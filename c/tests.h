#ifndef TESTS_H_
#define TESTS_H_

// Poor man's testing macros

#define TEST(group, name) static void test_##group##_##name(void)

#define EXPECT_NUM_BINOP(op, a, b)                                            \
  do {                                                                        \
    int test_expect_ok = (a)op(b);                                            \
    if (!test_expect_ok)                                                      \
      fprintf(stderr, "%-3.3s [%s] %s [%s]\n", test_expect_ok ? "OK" : "BAD", \
              #a, #op, #b);                                                   \
    /* if (!test_expect_ok) { abort(); } */                                   \
  } while (0)

#define EXPECT_STR_BINOP(op, a, b)                                            \
  do {                                                                        \
    int test_expect_ok = strcmp((a), (b)) op 0;                               \
    if (!test_expect_ok)                                                      \
      fprintf(stderr, "%-3.3s [%s] %s [%s]\n", test_expect_ok ? "OK" : "BAD", \
              #a, #op, #b);                                                   \
    /* if (!test_expect_ok) { abort(); } */                                   \
  } while (0)

#define EXPECT_NUM_EQ(a, b) EXPECT_NUM_BINOP(==, a, b)
#define EXPECT_NUM_NE(a, b) EXPECT_NUM_BINOP(!=, a, b)
#define EXPECT_NUM_LT(a, b) EXPECT_NUM_BINOP(<, a, b)
#define EXPECT_NUM_LE(a, b) EXPECT_NUM_BINOP(<=, a, b)
#define EXPECT_NUM_GT(a, b) EXPECT_NUM_BINOP(>, a, b)
#define EXPECT_NUM_GE(a, b) EXPECT_NUM_BINOP(>=, a, b)

#define EXPECT_STR_EQ(a, b) EXPECT_STR_BINOP(==, a, b)
#define EXPECT_STR_NE(a, b) EXPECT_STR_BINOP(!=, a, b)
#define EXPECT_STR_LT(a, b) EXPECT_STR_BINOP(<, a, b)
#define EXPECT_STR_LE(a, b) EXPECT_STR_BINOP(<=, a, b)
#define EXPECT_STR_GT(a, b) EXPECT_STR_BINOP(>, a, b)
#define EXPECT_STR_GE(a, b) EXPECT_STR_BINOP(>=, a, b)

#endif
