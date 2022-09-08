workspace(name = "openlocationcode")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Include the Google Test framework for C++ testing.
# See https://github.com/google/googletest
http_archive(
    name = "gtest",
    url = "https://github.com/google/googletest/archive/release-1.8.0.zip",
    sha256 = "f3ed3b58511efd272eb074a3a6d6fb79d7c2e6a0e374323d1e6bcbcc1ef141bf",
    build_file = "//cpp:gtest.BUILD",
    strip_prefix = "googletest-release-1.8.0/googletest",
)

# Include the Bazel Closure rules for javascript testing..
# See https://github.com/bazelbuild/rules_closure
# zlib library is required for com_google_protobuf which is loaded by the closure rules.
# skylib library required by closure rules.
# See the Closure WORKSPACE files for the above.
# Closure rules are pulled in at a specific commit because the current release
# (0.8.0) doesn't work with Bazel 0.24.1+.
http_archive(
    name = "net_zlib",
    # Original build file reference doesn't work. Fails with:
    #   Unable to load package for //:third_party/zlib.BUILD: not found. and referenced by '//external:zlib'
    # build_file = "//:third_party/zlib.BUILD",
    build_file = "@com_google_protobuf//:third_party/zlib.BUILD",
    sha256 = "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1",
    strip_prefix = "zlib-1.2.11",
    urls = [
        "https://mirror.bazel.build/zlib.net/zlib-1.2.11.tar.gz",
        "https://zlib.net/zlib-1.2.11.tar.gz",
    ],
)
# com_google_protobuf depends on zlib, not net_zlib, so we need to bind.
bind(
    name = "zlib",
    actual = "@net_zlib//:zlib",
)
http_archive(
    name = "bazel_skylib",
    sha256 = "bbccf674aa441c266df9894182d80de104cabd19be98be002f6d478aaa31574d",
    strip_prefix = "bazel-skylib-2169ae1c374aab4a09aa90e65efe1a3aad4e279b",
    urls = ["https://github.com/bazelbuild/bazel-skylib/archive/2169ae1c374aab4a09aa90e65efe1a3aad4e279b.tar.gz"],
)
http_archive(
    name = "io_bazel_rules_closure",
    sha256 = "1c05fea22c9630cf1047f25d008780756373a60ddd4d2a6993cf9858279c5da6",
    strip_prefix = "rules_closure-50d3dc9e6d27a5577a0f95708466718825d579f4",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_closure/archive/50d3dc9e6d27a5577a0f95708466718825d579f4.tar.gz",
        "https://github.com/bazelbuild/rules_closure/archive/50d3dc9e6d27a5577a0f95708466718825d579f4.tar.gz",
    ],
)
load("@io_bazel_rules_closure//closure:defs.bzl", "closure_repositories")
closure_repositories()
