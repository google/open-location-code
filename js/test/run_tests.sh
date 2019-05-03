#!/bin/bash

npm install

# Convert the CSV test files to JSON and put them in the test directory for serving.
go run ../test_data/csv_to_json.go --csv ../test_data/decoding.csv >test/decoding.json
go run ../test_data/csv_to_json.go --csv ../test_data/encoding.csv >test/encoding.json
go run ../test_data/csv_to_json.go --csv ../test_data/shortCodeTests.csv >test/shortCodeTests.json
go run ../test_data/csv_to_json.go --csv ../test_data/validityTests.csv >test/validityTests.json

# Run eslint based on local installs as well as in PATH.
# eslint errors will cause a build failure.
if [ -f ./node_modules/.bin/eslint ]; then
  ./node_modules/.bin/eslint src/openlocationcode.js && npm test
else
  eslint openlocationcode.js && npm test
fi
