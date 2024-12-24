# Load the necessary Closure rules
load("@io_bazel_rules_closure//closure:defs.bzl", "closure_js_library", "closure_js_test")

# Define the Closure library for Open Location Code
closure_js_library(
    name = "openlocationcode_lib",
    srcs = ["openlocationcode.js"],
    convention = "GOOGLE",
)

# Define the Closure test for Open Location Code
closure_js_test(
    name = "openlocationcode_test",
    timeout = "short",
    srcs = ["openlocationcode_test.js"],
    data = [
        "//test_data:test_data",  # Reference the filegroup for test data
    ],
    entry_points = ["goog:openlocationcode_test"],
    deps = [
        ":openlocationcode_lib",
        "@com_google_javascript_closure_library//closure/goog/net:eventtype",
        "@com_google_javascript_closure_library//closure/goog/net:xhrio",
        "@com_google_javascript_closure_library//closure/goog/testing:asserts",
        "@com_google_javascript_closure_library//closure/goog/testing:asynctestcase",
        "@com_google_javascript_closure_library//closure/goog/testing:testsuite",
    ],
)
