#!/bin/bash
# Script to execute the JS tests for the travis-ci.org integration testing
# platform.
# The script needs to test each implementation in turn, and return a failure
# if any script fails.

# Javascript
cd js
npm install && npm test
JS_RETURN_CODE=$?
echo "Javascript tests completed with return code: $JS_RETURN_CODE"

# Add other languages here...

# The return code is the total of the return codes of the tests, so that if
# any of them fail, a failure will be signaled.
exit $(($JS_RETURN_CODE))
