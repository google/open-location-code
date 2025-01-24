#!/bin/bash
# Run lint checks on files in the Javascript directory.
# Also converts the test CSV files to JSON ready for the tests to execute.
# Note: must run within the JS directory.
if [ `basename "$PWD"` != "js" ]; then
  echo "$0: must be run from within the js directory!"
  exit 1
fi

# Require that the NPM install and CSV conversion commands succeed.
set -e

# Install all the dependencies.
npm install

# Convert the CSV test files to JSON and put them in the test directory for serving.
go run ../test_data/csv_to_json.go --csv ../test_data/decoding.csv >test/decoding.json
go run ../test_data/csv_to_json.go --csv ../test_data/encoding.csv >test/encoding.json
go run ../test_data/csv_to_json.go --csv ../test_data/shortCodeTests.csv >test/shortCodeTests.json
go run ../test_data/csv_to_json.go --csv ../test_data/validityTests.csv >test/validityTests.json

set +e

# Run the tests
npm test
# Save the return value for the end.
RETURN=$?

# Run eslint based on local installs as well as in PATH.
# eslint errors will cause a build failure.
ESLINT=eslint
$ESLINT --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  ESLINT=./node_modules/.bin/eslint
fi

$ESLINT --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "\e[1;31mCannot find eslint, check your installation\e[0m"
else
  # Run eslint on the source file.
  FILE=src/openlocationcode.js
  LINT=`$ESLINT $FILE`
  if [ $? -ne 0 ]; then
    echo -e "\e[1;31mFile has formatting errors:\e[0m"
    echo "$LINT"
    RETURN=1
  fi
fi
exit $RETURN
