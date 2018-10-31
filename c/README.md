# Open Location Code C API
This is the C implementation of the Open Location Code API.

# Usage

See example.cc for how to use the library. To run the example, use:

```
bazel run example
```

# Development

The library is built/tested using [Bazel](https://bazel.build). To build the library, use:

```
bazel build olc
```

To run the tests, use:

```
bazel test --test_output=all olc_test
```

The tests use the CSV files in the test_data folder. Make sure you copy this folder to the
root of your local workspace.
