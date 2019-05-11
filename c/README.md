# Open Location Code C API

This is the C implementation of the Open Location Code API.

# Code Style and Formatting

Code style is based on Googles formatting rules. Code must be formatted
using `clang-format`.

The `clang_check.sh` script will check for formatting errors, output them,
and automatically format files.

# Usage

See example.cc for how to use the library. To run the example, use:

```
bazel run openlocationcode_example
```

# Development

The library is built/tested using [Bazel](https://bazel.build). To build the library, use:

```
bazel build openlocationcode
```

To run the tests, use:

```
bazel test --test_output=all openlocationcode_test
```

The tests use the CSV files in the test_data folder. Make sure you copy this folder to the
root of your local workspace.


# Authors

* The authors of the C++ implementation, on which this is based.
* [Gonzalo Diethelm](mailto:gonzalo.diethelm@gmail.com)
