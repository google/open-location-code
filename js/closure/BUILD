load("@io_bazel_rules_closure//closure:defs.bzl", "closure_js_library", "closure_js_test")

closure_js_library(
    name = "openlocationcode_lib",
    srcs = ["openlocationcode.js"],
    deps = [
        "@io_bazel_rules_closure//closure/library",
    ],
)

closure_js_test(
    name = "openlocationcode_test",
    timeout = "short",
    srcs = ["openlocationcode_test.js"],
    entry_points = ["goog:openlocationcode_test"],
    deps = [
        ":openlocationcode_lib",
        "@io_bazel_rules_closure//closure/library:testing",
    ],
)
