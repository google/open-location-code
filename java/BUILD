java_library(
    name = "openlocationcode",
    srcs = [
        "src/main/java/com/google/openlocationcode/OpenLocationCode.java",
    ],
)

java_test(
    name = "EncodingTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/EncodingTest.java",
    ],
    data = [
        "//test_data:test_data"
    ],
    test_class = "com.google.openlocationcode.EncodingTest",
    deps = [
        ":openlocationcode",
    ],
)

java_test(
    name = "ShorteningTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/ShorteningTest.java",
    ],
    data = [
        "//test_data:test_data"
    ],
    test_class = "com.google.openlocationcode.ShorteningTest",
    deps = [
        ":openlocationcode",
    ],
)

java_test(
    name = "ValidityTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/ValidityTest.java",
    ],
    data = [
        "//test_data:test_data"
    ],
    test_class = "com.google.openlocationcode.ValidityTest",
    deps = [
        ":openlocationcode",
    ],
)

java_test(
    name = "PrecisionTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/PrecisionTest.java",
    ],
    test_class = "com.google.openlocationcode.PrecisionTest",
    deps = [
        ":openlocationcode",
    ],
)

java_test(
    name = "RecoverTest",
    size = "small",
    srcs = [
        "src/test/java/com/google/openlocationcode/RecoverTest.java",
    ],
    test_class = "com.google.openlocationcode.RecoverTest",
    deps = [
        ":openlocationcode",
    ],
)
