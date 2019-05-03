#!/bin/bash

npm install
# Run eslint based on local installs as well as in PATH
if [ -f ./node_modules/.bin/eslint ]; then
  ./node_modules/.bin/eslint src/openlocationcode.js
else
  eslint openlocationcode.js
fi

# Convert the CSV test files to JSON
go run ../test_data/csv_to_json.go --csv ../test_data/decoding.csv >test/decoding.json
go run ../test_data/csv_to_json.go --csv ../test_data/encoding.csv >test/encoding.json
go run ../test_data/csv_to_json.go --csv ../test_data/shortCodeTests.csv >test/shortCodeTests.json
go run ../test_data/csv_to_json.go --csv ../test_data/validityTests.csv >test/validityTests.json

# Run the tests.
npm test
