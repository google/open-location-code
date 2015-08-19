#!/bin/bash
# Script to execute the JS tests for the travis-ci.org integration testing
# platform.
# The script needs to test each implementation in turn, and return a failure
# if any script fails.

# Javascript
cd js
npm install && npm test
RETURN_CODE=$((0+$?))

# Add other languages here...

# The return code is the total of the return codes of the tests, so that if
# any of them fail, a failure will be signaled.
exit $RETURN_CODE
