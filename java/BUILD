java_library(
    name = "openlocationcode",
    srcs = [
        "src/main/java/com/google/openlocationcode/OpenLocationCode.java",
    ],
)

java_test(
    name = "IntegrationTest",
    size = "medium",
    srcs = [
        "src/test/java/IntegrationTestSuite.java",
        "src/test/java/com/google/openlocationcode/DecodingTest.java",
        "src/test/java/com/google/openlocationcode/EncodingTest.java",
        "src/test/java/com/google/openlocationcode/PrecisionTest.java",
        "src/test/java/com/google/openlocationcode/RecoverTest.java",
        "src/test/java/com/google/openlocationcode/ShorteningTest.java",
        "src/test/java/com/google/openlocationcode/UtilsTest.java",
        "src/test/java/com/google/openlocationcode/ValidityTest.java",
        "src/test/java/com/google/openlocationcode/TestUtils.java",
    ],
    data = [
        "//test_data:test_data"
    ],
    test_class = "IntegrationTestSuite",
    deps = [
        ":openlocationcode",
    ],
)
