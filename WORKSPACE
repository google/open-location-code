workspace(name = "openlocationcode")

# Include the Google Test framework for C++ testing.
# See https://github.com/google/googletest
new_http_archive(
    name = "gtest",
    url = "https://github.com/google/googletest/archive/release-1.8.0.zip",
    sha256 = "f3ed3b58511efd272eb074a3a6d6fb79d7c2e6a0e374323d1e6bcbcc1ef141bf",
    build_file = "cpp/gtest.BUILD",
    strip_prefix = "googletest-release-1.8.0/googletest",
)

# Include the Bazel Closure rules for javascript testing..
# See https://github.com/bazelbuild/rules_closure
http_archive(
    name = "io_bazel_rules_closure",
    url = "http://mirror.bazel.build/github.com/bazelbuild/rules_closure/archive/0.4.1.tar.gz",
    sha256 = "ba5e2e10cdc4027702f96e9bdc536c6595decafa94847d08ae28c6cb48225124",
    strip_prefix = "rules_closure-0.4.1",
)

load("@io_bazel_rules_closure//closure:defs.bzl", "closure_repositories")

closure_repositories()

