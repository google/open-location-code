java_library(
    name = "openlocationcode",
    srcs = [
        "com/google/openlocationcode/OpenLocationCode.java",
    ],
)

java_test(
    name = "EncodingTest",
    size = "small",
    srcs = [
        "com/google/openlocationcode/tests/EncodingTest.java",
    ],
    data = [
        "//test_data:test_data"
    ],
    test_class = "com.google.openlocationcode.tests.EncodingTest",
    deps = [
        ":openlocationcode",
    ],
)

java_test(
    name = "ShorteningTest",
    size = "small",
    srcs = [
        "com/google/openlocationcode/tests/ShorteningTest.java",
    ],
    data = [
        "//test_data:test_data"
    ],
    test_class = "com.google.openlocationcode.tests.ShorteningTest",
    deps = [
        ":openlocationcode",
    ],
)

java_test(
    name = "ValidityTest",
    size = "small",
    srcs = [
        "com/google/openlocationcode/tests/ValidityTest.java",
    ],
    data = [
        "//test_data:test_data"
    ],
    test_class = "com.google.openlocationcode.tests.ValidityTest",
    deps = [
        ":openlocationcode",
    ],
)

java_test(
    name = "PrecisionTest",
    size = "small",
    srcs = [
        "com/google/openlocationcode/tests/PrecisionTest.java",
    ],
    test_class = "com.google.openlocationcode.tests.PrecisionTest",
    deps = [
        ":openlocationcode",
    ],
)

java_test(
    name = "RecoverTest",
    size = "small",
    srcs = [
        "com/google/openlocationcode/tests/RecoverTest.java",
    ],
    test_class = "com.google.openlocationcode.tests.RecoverTest",
    deps = [
        ":openlocationcode",
    ],
)
