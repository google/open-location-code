# Java Open Location Code library

This is the Java implementation of OLC. You can build the library either with [Maven](https://maven.apache.org/) or [Bazel](https://bazel.build/).

## Code Style

The Java code must use the Google formatting guidelines. Format is checked using
[google-java-format](https://github.com/google/google-java-format).

The formatting is checked in the tests and formatting errors will cause tests
to fail and comments to be added to your PR.

You can ensure your files are formatted correctly either by installing
google-java-format into your editor, or by running `mvn spotless:check`.

## Static Analysis

Code is checked for common flaws with [PMD](https://pmd.github.io). It can be
executed by running `mvn pmd:pmd pmd:check`.

## Building and Testing

Note: the tests read their data from the [`test_data`](https://github.com/google/open-location-code/blob/main/test_data) directory.

### Maven

Install Maven on your system. From the java folder, run:

```
$ mvn package
...
-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running com.google.openlocationcode.EncodingTest
Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.045 sec
Running com.google.openlocationcode.PrecisionTest
Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0 sec
Running com.google.openlocationcode.RecoverTest
Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0 sec
Running com.google.openlocationcode.ShorteningTest
Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.001 sec
Running com.google.openlocationcode.ValidityTest
Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.001 sec

Results :

Tests run: 13, Failures: 0, Errors: 0, Skipped: 0
...
[INFO] BUILD SUCCESS

```
This will compile the library, run the tests, and output a JAR under the generated "target" directory.

### Bazel

Included is a `BUILD` file that uses the Bazel build system to produce a JAR file and to run tests. You will need to install Bazel on your system to compile the library and run the tests.

To build a JAR file, run from the java folder:

```
$ bazel build java:openlocationcode
INFO: Found 1 target...
Target //java:openlocationcode up-to-date:
  bazel-bin/java/libopenlocationcode.jar
INFO: Elapsed time: 3.107s, Critical Path: 0.22s
$
```

The JAR file is accessible using the path shown in the output.

If you cannot install Bazel, you can build the JAR file manually with:

```
mkdir build
javac -d build src/main/java/com/google/openlocationcode/OpenLocationCode.java
```

This will create a JAR file in the `build` directory. Change that to a suitable location.

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

## MavenCentral

The library is available to import/download via [Maven Central](https://search.maven.org/search?q=g:com.google.openlocationcode).

To update the library, bump the version number in pom.xml and run "mvn clean deploy" from the java folder. See the [docs](https://central.sonatype.org/pages/apache-maven.html) for more info.
