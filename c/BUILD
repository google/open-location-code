# Rule to build the library.
cc_library(
    name = "openlocationcode",
    srcs = [
        "src/olc.c",
    ],
    copts = ["-std=c99"],
    hdrs = [
        "src/olc.h",
        "src/olc_private.h",
    ],
    visibility = ["//visibility:public"],
)

# Rule to build and run the unit tests.
cc_test(
    name = "openlocationcode_test",
    size = "small",
    srcs = ["openlocationcode_test.cc"],
    copts = [
        "-pthread",
        "-Iexternal/gtest/include",
    ],
    data = [
        "//test_data",
    ],
    linkopts = ["-pthread"],
    deps = [
        ":openlocationcode",
        "@gtest//:main",
    ],
)

# Rule to build and run the example.
cc_binary(
    name = "openlocationcode_example",
    srcs = [
        "example.c",
    ],
    deps = [
        ":openlocationcode",
    ],
)
