# Automated Integration Testing
Changes are sent to [Travis CI](https://travis-ci.org)
for integration testing after pushes, and you can see the current test status
[here](https://travis-ci.org/google/open-location-code).

The testing configuration is controlled by two files:
[`travis.yml`](.travis.yml) and [`run_tests.sh`](run_tests.sh).

## [.travis.yml](.travis.yml)
This file defines the prerequisites required for testing, and the list of
directories to be tested. (The directories listed are tested in parallel.)

The same script ([run_tests.sh](run_tests.sh)) is executed for all directories.

## [run_tests.sh](run_tests.sh)
This file is run once for _each_ directory defined in
`.travis.yml`. The directory name being tested is passed in the environment
variable `TEST_DIR`.)

[`run_tests.sh`](run_tests.sh) checks the value of `TEST_DIR`, and then runs
commands to test the relevant implementation. The commands that do the testing
**must** return zero on success and non-zero value on failure. _Tests that
return zero, even if they output error messages, will be considered by the
testing framework as a success_.

## Adding Your Tests
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
  exit  # Exit immediately, returning the last command status
fi
```
Note the use of `&&` to combine the test commands. This ensures that if any
command in the sequence fails, the script will stop and return a test failure.

The test commands **must be** followed by an `exit` statement. This ensures that
the script will return the same status as the tests. If this status is zero,
the test will be marked successful. If not, the test will be marked as a
failure.

## Testing Multiple Languages
[Travis CI](https://travis-ci.org) assumes that each github project has only
a single language. That language is specified in the [.travis.yml](.travis.yml)
file (`language: node_js`).

This shouldn't be a problem, since prerequisites can still be loaded in the
`before_script` section, and then commands executed in
[`run_tests.sh`](run_tests.sh). However in the event that you can't resolve a
problem, leave a comment in the issue or push request and we'll see if someone
can figure out a solution.
