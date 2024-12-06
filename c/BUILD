cc_library(
    name = "openlocationcode",
    srcs = [
        "src/olc.c",
    ],
    copts = [
        "-std=c99",
        "-Wall",
        "-Wextra",
        "-O2",
    ],
    hdrs = [
        "src/olc.h",
        "src/olc_private.h",
    ],
    includes = ["src"],
    visibility = ["//visibility:private"],
)

cc_test(
    name = "openlocationcode_test",
    size = "small",
    srcs = ["openlocationcode_test.cc"],
    copts = [
        "-pthread",
        "-I@googletest//:include",
    ],
    linkopts = ["-pthread"],
    linkstatic = False,
    data = [
        "//test_data",
    ],
    deps = [
        ":openlocationcode",
        "@googletest//:gtest_main",
    ],
    testonly = True,
    visibility = ["//visibility:private"],
)

cc_binary(
    name = "openlocationcode_example",
    srcs = [
        "example.c",
    ],
    deps = [
        ":openlocationcode",
    ],
    visibility = ["//visibility:private"],
)