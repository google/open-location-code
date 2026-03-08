load("@rules_rust//rust:defs.bzl", "rust_library", "rust_test", "rust_test_suite")
load("@crates//:defs.bzl", "all_crate_deps")

rust_library(
    name = "open_location_code",
    srcs = glob(["src/**/*.rs"]),
    edition = "2024",
    visibility = ["//visibility:public"],
    deps = all_crate_deps(
        normal = True,
    ),
)

rust_test(
    name = "all_test",
    size = "small",
    srcs = [
        "tests/all_test.rs",
        "tests/csv_reader.rs",
    ],
    data = ["//test_data:test_data"],
    edition = "2024",
    proc_macro_deps = all_crate_deps(
        proc_macro_dev = True,
    ),
    deps = [
        ":open_location_code",
    ] + all_crate_deps(
        normal = True,
        normal_dev = True,
    ),
)
