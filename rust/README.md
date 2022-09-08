This is the Rust implementation of the Open Location Code library.

# Contributing

## Code Formatting

Code must be formatted with `rustfmt`. You can do this by running `cargo fmt`.

The formatting will be checked in the TravisCI integration tests. If the files
need formatting the tests will fail.

## Testing

Test code by running `cargo test -- --nocapture`. This will run the tests
including the benchmark loops.

