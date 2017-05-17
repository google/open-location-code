# Java Open Location Code library

## Building and Testing

Included is a `BUILD` file that uses the [Bazel](https://bazel.build/) build system to produce a JAR file and to run tests. You will need to install Bazel on your system to run the tests.

### Building the JAR file

To build a JAR file, run:

```
$ bazel build java:openlocationcode
INFO: Found 1 target...
Target //java:openlocationcode up-to-date:
  bazel-bin/java/libopenlocationcode.jar
INFO: Elapsed time: 3.107s, Critical Path: 0.22s
$
```

The JAR file is accessable using the path shown in the output.

If you cannot install Bazel, you can build the JAR file manually with:

```
mkdir build
javac -d build com/google/openlocationcode/OpenLocationCode.java
```

This will  create a JAR file in the `build` directory. Change that to a suitable location.

### Running tests

The tests read their data from the [`test_data`](https://github.com/google/open-location-code/tree/master/test_data) directory.

Run the tests from the top-level github directory. This command will build the JAR file and test classes, and execute them:

```
$ bazel test java:all
INFO: Found 1 target and 4 test targets...
INFO: Elapsed time: 0.657s, Critical Path: 0.46s
//java:encoding_Test                                                     PASSED in 0.4s
//java:precision_test                                                    PASSED in 0.4s
//java:shortening_test                                                   PASSED in 0.4s
//java:validity_test                                                     PASSED in 0.4s

Executed 4 out of 4 tests: 4 tests pass.
$
```

