# Load the necessary Closure rules
load("@rules_closure//closure:defs.bzl", "closure_js_library", "closure_js_test")

# Define the Closure library for Open Location Code
closure_js_library(
    name = "openlocationcode_lib",
    srcs = ["openlocationcode.js"],
    convention = "GOOGLE",
)

# Define the Closure test for Open Location Code
# Note: rules_closure 0.15.0 removed dependency on com_google_javascript_closure_library
# and now includes a forked test suite in the rules_closure package itself.
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
        "@rules_closure//closure/library/net:eventtype",
        "@rules_closure//closure/library/net:xhrio",
        "@rules_closure//closure/testing:asserts",
        "@rules_closure//closure/testing:asynctestcase",
        "@rules_closure//closure/testing:testsuite",
    ],
)
