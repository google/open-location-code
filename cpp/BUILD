# Library to handle open location codes
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

# Code area library, used by open location codes
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

# Unit test for open location codes
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

# Unit test for code area library
cc_test(
    name = "codearea_test",
    size = "small",
    srcs = ["codearea_test.cc"],
    copts = [
        "-pthread",
        "-Iexternal/gtest/include",
    ],
    linkopts = ["-pthread"],
    deps = [
        ":codearea",
        "@gtest//:main",
    ],
)

# Example binary for open location codes
cc_binary(
    name = "openlocationcode_example",
    srcs = [
        "openlocationcode_example.cc",
    ],
    deps = [
        ":openlocationcode",
    ],
)