package(default_visibility = ["//visibility:public"])

py_library(
    name = "openlocationcode",
    srcs = ["openlocationcode.py"],
)

py_test(
    name = "openlocationcode_test",
    size = "small",
    srcs = ["openlocationcode_test.py"],
    data = ["//test_data:test_data"],
    python_version = "PY3",
    deps = [":openlocationcode"],
)
