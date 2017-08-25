cc_library(
    name = "openlocationcode",
    srcs = [
        "openlocationcode.cc",
    ],
    hdrs = [
        "codearea.h",
        "openlocationcode.h",
    ],
    deps = [
        ":codearea",
    ],
    copts = ["-pthread"],
    linkopts = ["-pthread"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "codearea",
    srcs = [
        "codearea.cc",
    ],
    hdrs = [
        "codearea.h",
    ],
    visibility = ["//visibility:private"],
)

cc_test(
    name = "openlocationcode_test",
    size = "small",
    srcs = ["openlocationcode_test.cc"],
    data = [
        "//test_data:test_data",
    ],
    deps = [
        "@gtest//:main",
        ":openlocationcode",
    ],
    copts = ["-pthread", "-Iexternal/gtest/include"],
    linkopts = ["-pthread"],
)

cc_binary(
    name = "openlocationcode_example",
    srcs = [
        "openlocationcode_example.cc",
    ],
    deps = [
        ":openlocationcode",
    ],
)
