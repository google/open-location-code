### Automated Integration Testing
Changes are sent to [Travis CI](https://travis-ci.org)
for integration testing after pushes.

Open Location Code's [current test status](https://travis-ci.org/google/open-location-code).

The testing is controlled by two files: [`.travis.yml`](.travis.yml) and
[`run_tests.sh`](run_tests.sh).

[`.travis.yml`](.travis.yml) includes any prerequisites required for testing, and also defines
the list of directories to be tested. The directories are tested in parallel.

[`run_tests.sh`](run_tests.sh) is run once for each directory defined in
`.travis.yml`. (The directory name is passed in the environment variable
`TEST_DIR`.)

[`run_tests.sh`](run_tests.sh) has to check the value of `TEST_DIR`, and then
do whatever is necessary to test that implementation. The code to test must
return 0 on success and another value on failure. _Just outputting a failure
message will be considered by the testing framework as a success_.

### Adding Your Tests
Add your directory to the [`.travis.yml`](.travis.yml) file:
```
# Define the list of directories to execute tests in.
env:
  - TEST_DIR=js
  - TEST_DIR=go
  - TEST_DIR=your directory goes here
```

Then add the necessary code to [`run_tests.sh`](run_tests.sh):
```
# Your language goes here
if [ "$TEST_DIR" == "your directory goes here" ]; then
  cd directory && run something && run another thing
  exit
fi
```
Note the use of `&&` to combine the test commands. This ensures that if any of
them fail, it will stop and return a test failure.

The test commands are followed by an `exit` statement that will immediately
return the last command status as the result. If this is zero, the test will
be marked successful. If not, the test will be marked as a failure.
