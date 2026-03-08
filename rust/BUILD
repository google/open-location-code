load("@rules_rust//rust:defs.bzl", "rust_library", "rust_test")
load("@crates//:defs.bzl", "all_crate_deps")

rust_library(
    name = "open_location_code",
    srcs = [
        "src/lib.rs",
        "src/codearea.rs",
        "src/consts.rs",
        "src/interface.rs",
        "src/private.rs",
    ],
    deps = all_crate_deps(
        normal = True,
    ),
    visibility = ["//visibility:private"],
)

rust_test(
    name = "all_test",
    size = "small",
    srcs = [
        "tests/all_test.rs",
        "tests/csv_reader.rs",
    ],
    data = ["//test_data"],
    deps = [
        ":open_location_code",
    ] + all_crate_deps(
        normal = True,
        normal_dev = True,
    ),
    visibility = ["//visibility:private"],
)
