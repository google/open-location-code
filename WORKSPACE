# Workspace configuration for Bazel build tools.

# TODO: #642 -- Remove once io_bazel_rules_closure supports Bazel module configuration.
workspace(name = "openlocationcode")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "io_bazel_rules_closure",
    integrity = "sha256-EvEWnr54L4Yx/LjagaoSuhkviVKHW0oejyDEn8bhAiM=",
    strip_prefix = "rules_closure-0.14.0",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_closure/archive/0.14.0.tar.gz",
        "https://github.com/bazelbuild/rules_closure/archive/0.14.0.tar.gz",
    ],
)
load("@io_bazel_rules_closure//closure:repositories.bzl", "rules_closure_dependencies", "rules_closure_toolchains")
rules_closure_dependencies()
rules_closure_toolchains()
