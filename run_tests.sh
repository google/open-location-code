#!/bin/bash
# Script to execute the JS tests for the travis-ci.org integration testing
# platform.
# The script needs to test each implementation in turn, and return a failure
# if any script fails.
# The language to test comes as the environment variable TEST_LANG.

set -ev

# Javascript?
if [ "$TEST_LANG" == "js" ]; then
  cd js && npm install && npm test
  exit $?
fi

echo "Unknown test lang: $TEST_LANG"
