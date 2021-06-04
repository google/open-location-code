#include <stdio.h>
#include <string.h>

/*
 * This file is included in the C and C++ benchmark.
 * This ensures it is compiled natively by the C / C++ compiler.
 */

#define OLC_SCALE 1000000

#if !defined(OLC_CHECK_RESULTS)
#define OLC_CHECK_RESULTS 0
#endif

#if defined(OLC_CHECK_RESULTS) && OLC_CHECK_RESULTS > 0
#define ASSERT_STR_EQ(var, str)                                              \
  do {                                                                       \
    int assert_str_ok = strcmp(var, str) == 0;                               \
    if (!assert_str_ok) {                                                    \
      fprintf(stderr, "%s %d [%s] != [%s] (%s)\n", __FILE__, __LINE__, #var, \
              str, var);                                                     \
      abort();                                                               \
    }                                                                        \
  } while (0)

#define ASSERT_INT_EQ(var, num)                                                \
  do {                                                                         \
    int assert_int_ok = var == num;                                            \
    if (!assert_int_ok) {                                                      \
      fprintf(stderr, "%s %d [%s] != [%ld] (%ld)\n", __FILE__, __LINE__, #var, \
              (long)num, (long)var);                                           \
      abort();                                                                 \
    }                                                                          \
  } while (0)

#define ASSERT_FLT_EQ(var, num)                                                \
  do {                                                                         \
    int assert_flt_ok = ((unsigned long long)(var * OLC_SCALE)) ==             \
                        ((unsigned long long)(num * OLC_SCALE));               \
    if (!assert_flt_ok) {                                                      \
      fprintf(stderr, "%s %d [%s] != [%lf] (%lf)\n", __FILE__, __LINE__, #var, \
              (double)num, (double)var);                                       \
      abort();                                                                 \
    }                                                                          \
  } while (0)

#else

#define ASSERT_STR_EQ(var, str) (void)(var)
#define ASSERT_INT_EQ(var, num) (void)(var)
#define ASSERT_FLT_EQ(var, num) (void)(var)

#endif

double data_pos_lat = 47.0000625;
double data_pos_lon = 8.0000625;
int data_pos_len = 16;
const char* data_code_16 = "8FVC2222+22GCCCC";
const char* data_code_12 = "9C3W9QCJ+2VX";
const char* data_code_6 = "CJ+2VX";
double data_ref_lat = 51.3708675;
double data_ref_lon = -1.217765625;

typedef void(Tester)(void);

static void encode(void);
static void encode_len(void);
static void decode(void);
static void is_valid(void);
static void is_full(void);
static void is_short(void);
static void shorten(void);
static void recover(void);

typedef struct Data {
  const char* name;
  Tester* tester;
} Data;

static struct Data data[] = {
    {"decode", decode},   {"encode", encode},     {"encode_len", encode_len},
    {"is_full", is_full}, {"is_short", is_short}, {"is_valid", is_valid},
    {"recover", recover}, {"shorten", shorten},
};

static double now_us(void) {
  struct timeval tv;
  double now = 0.0;
  int rc = gettimeofday(&tv, 0);
  if (rc == 0) {
    now = 1000000.0 * tv.tv_sec + tv.tv_usec;
  }
  return now;
}

static int run(int argc, char* argv[]) {
  int runs = 1;
  if (argc > 1) {
    runs = atoi(argv[1]);
  }

  int total = sizeof(data) / sizeof(data[0]);
  for (int j = 0; j < total; ++j) {
    const char* name = data[j].name;
    Tester* tester = data[j].tester;

    double t0 = now_us();
    for (int k = 0; k < runs; ++k) {
      tester();
    }
    double t1 = now_us();
    double elapsed = t1 - t0;
    double per_ms = 1000.0 * runs / elapsed;
    printf("%-10.10s %-20.20s %10d runs %10lu us %10lu runs/ms\n", argv[0],
           name, runs, (unsigned long)elapsed, (unsigned long)per_ms);
  }
  return 0;
}
