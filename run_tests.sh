#!/bin/bash
# Script to execute the JS tests for the travis-ci.org integration testing
# platform.
# The directory to test comes as the environment variable TEST_DIR. The script
# needs to check for it, change into it, and run the tests as necessary.

set -ev

# Go?
if [ "$TEST_DIR" == "go" ]; then
  go test ./go
  exit $?
fi
# Javascript?
if [ "$TEST_DIR" == "js" ]; then
  cd js && npm install && npm test
  exit $?
fi

echo "Unknown test directory: $TEST_DIR"
