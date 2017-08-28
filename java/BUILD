
java_library(
    name = "openlocationcode",
    srcs = [
        "com/google/openlocationcode/OpenLocationCode.java",
    ],
)

java_test(
    name = "encoding_Test",
    srcs = [
        "com/google/openlocationcode/tests/EncodingTest.java",
    ],
    test_class = "com.google.openlocationcode.tests.EncodingTest",
    size = "small",
    deps = [
        ":openlocationcode",
    ],
    data = [
        "//test_data:test_data"
    ],
)

java_test(
    name = "shortening_test",
    srcs = [
        "com/google/openlocationcode/tests/ShorteningTest.java",
    ],
    test_class = "com.google.openlocationcode.tests.ShorteningTest",
    size = "small",
    deps = [
        ":openlocationcode",
    ],
    data = [
        "//test_data:test_data"
    ],
)

java_test(
    name = "validity_test",
    srcs = [
        "com/google/openlocationcode/tests/ValidityTest.java",
    ],
    test_class = "com.google.openlocationcode.tests.ValidityTest",
    size = "small",
    deps = [
        ":openlocationcode",
    ],
    data = [
        "//test_data:test_data"
    ],
)

java_test(
    name = "precision_test",
    srcs = [
        "com/google/openlocationcode/tests/PrecisionTest.java",
    ],
    test_class = "com.google.openlocationcode.tests.PrecisionTest",
    size = "small",
    deps = [
        ":openlocationcode",
    ],
)

java_test(
    name = "recover_test",
    srcs = [
        "com/google/openlocationcode/tests/RecoverTest.java",
    ],
    test_class = "com.google.openlocationcode.tests.RecoverTest",
    size = "small",
    deps = [
        ":openlocationcode",
    ],
)
