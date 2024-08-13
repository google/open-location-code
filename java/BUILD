java_library(
    name = "openlocationcode",
    srcs = [
        "src/main/java/com/google/openlocationcode/OpenLocationCode.java",
    ],
    visibility = ["//visibility:private"],
)

java_test(
    name = "BenchmarkTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/BenchmarkTest.java",
    ],
    test_class = "com.google.openlocationcode.BenchmarkTest",
    deps = [
        ":openlocationcode",
    ],
    visibility = ["//visibility:private"],
)

java_test(
    name = "DecodingTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/DecodingTest.java",
        "src/test/java/com/google/openlocationcode/TestUtils.java",
    ],
    data = [
        "//test_data:test_data"
    ],
    test_class = "com.google.openlocationcode.DecodingTest",
    deps = [
        ":openlocationcode",
    ],
    visibility = ["//visibility:private"],
)

java_test(
    name = "EncodingTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/EncodingTest.java",
        "src/test/java/com/google/openlocationcode/TestUtils.java",
    ],
    data = [
        "//test_data:test_data"
    ],
    test_class = "com.google.openlocationcode.EncodingTest",
    deps = [
        ":openlocationcode",
    ],
    visibility = ["//visibility:private"],
)

java_test(
    name = "ShorteningTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/ShorteningTest.java",
        "src/test/java/com/google/openlocationcode/TestUtils.java",
    ],
    data = [
        "//test_data:test_data"
    ],
    test_class = "com.google.openlocationcode.ShorteningTest",
    deps = [
        ":openlocationcode",
    ],
    visibility = ["//visibility:private"],
)

java_test(
    name = "ValidityTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/ValidityTest.java",
        "src/test/java/com/google/openlocationcode/TestUtils.java",
    ],
    data = [
        "//test_data:test_data"
    ],
    test_class = "com.google.openlocationcode.ValidityTest",
    deps = [
        ":openlocationcode",
    ],
    visibility = ["//visibility:private"],
)

java_test(
    name = "PrecisionTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/PrecisionTest.java",
        "src/test/java/com/google/openlocationcode/TestUtils.java",
    ],
    test_class = "com.google.openlocationcode.PrecisionTest",
    deps = [
        ":openlocationcode",
    ],
    visibility = ["//visibility:private"],
)

java_test(
    name = "RecoverTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/RecoverTest.java",
        "src/test/java/com/google/openlocationcode/TestUtils.java",
    ],
    test_class = "com.google.openlocationcode.RecoverTest",
    deps = [
        ":openlocationcode",
    ],
    visibility = ["//visibility:private"],
)

java_test(
    name = "UtilsTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/UtilsTest.java",
        "src/test/java/com/google/openlocationcode/TestUtils.java",
    ],
    test_class = "com.google.openlocationcode.UtilsTest",
    deps = [
        ":openlocationcode",
    ],
    visibility = ["//visibility:private"],
)
