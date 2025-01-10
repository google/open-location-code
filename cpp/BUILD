# Library to handle Plus Codes
cc_library(
    name = "openlocationcode",
    srcs = [
        "openlocationcode.cc",
    ],
    hdrs = [
        "codearea.h",
        "openlocationcode.h",
    ],
    copts = [
        "-pthread",
        "-Wall",
        "-Wextra",
        "-O2",
    ],
    linkopts = ["-pthread"],
    deps = [
        ":codearea",
    ],
)

# Code area library, used by Open Location Code
cc_library(
    name = "codearea",
    srcs = [
        "codearea.cc",
    ],
    hdrs = [
        "codearea.h",
    ],
    visibility = ["//visibility:private"],  # Keep private unless needed elsewhere
)

# Unit test for Open Location Code implementations
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
)

# Example binary for Open Location Code
cc_binary(
    name = "openlocationcode_example",
    srcs = [
        "openlocationcode_example.cc",
    ],
    deps = [
        ":openlocationcode",
    ],
)