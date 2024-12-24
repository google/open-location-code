# Closure Library

This is a version of the Open Location Code javascript library for use with the
[Google Closure Compiler](https://github.com/google/closure-compiler).

You can use it in Closure projects like this:

```javascript
  const openlocationcode = goog.require('google.openlocationcode');
  ...
  var code = openlocationcode.encode(47.36628,8.52513);
```

## Code Style And Formatting

Code should be formatted according to the
[Google JavaScript Style Guide](https://google.github.io/styleguide/jsguide.html).

You can run checks on the code using `eslint`:

```
cd js
npm install eslint
eslint closure/*js
```

If there are any syntax or style errors, it will output messages. Note that
syntax or style errors will cause the TravisCI tests to **fail**.

## Building and Testing

Included is a `BUILD` file that uses the [Bazel](https://bazel.build/) build system to produce a JavaScript library and to run tests. You will need to install Bazel on your system to run the tests.

The tests use the [Closure Rules for Basel](https://github.com/bazelbuild/rules_closure) project although this is retrieved automatically and you don't have to install anything.

The test cases have been copied from the [`test_data`](https://github.com/google/open-location-code/blob/main/test_data) directory due to restrictions on loading data files within the test runner.

Run the tests from the top-level github directory with:

```
$ bazel test js/closure:openlocationcode_test
INFO: Found 1 test target...
Target //js/closure:openlocationcode_test up-to-date:
  bazel-bin/js/closure/openlocationcode_test
INFO: Elapsed time: 0.174s, Critical Path: 0.00s
//js/closure:openlocationcode_test                                       PASSED in 1.1s

Executed 0 out of 1 test: 1 test passes.
$
```

