py_library(
    name = "openlocationcode",
    srcs = ["openlocationcode/openlocationcode.py"],
)

py_test(
    name = "openlocationcode_test",
    python_version = "PY3",
    size = "small",
    srcs = ["openlocationcode_test.py"],
    data = ["//test_data:test_data"],
    deps = [":openlocationcode"],
    visibility = ["//visibility:private"]
)