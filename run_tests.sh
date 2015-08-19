#!/bin/bash
# Script to execute the JS tests for the travis-ci.org integration testing
# platform.
# The script needs to test each implementation in turn, and return a failure
# if any script fails.

# Javascript
pushd js && npm install && npm test
JS_RETURN_CODE=$?
popd
echo "Javascript tests completed with return code: $JS_RETURN_CODE"

# Add other languages above. Each language should be of the form:
# pushd $DIR && test command
# LANG_RETURN_CODE=$?
# popd
# Make sure to add $LANG_RETURN_CODE into the exit statement at the bottom of
# the file.

# The return code is the total of the return codes of the tests, so that if
# any of them fail, a failure will be signaled.
exit $(($JS_RETURN_CODE))
