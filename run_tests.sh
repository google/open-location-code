#!/bin/bash
# Execute the JS tests for travis-ci.org integration testing platform.
# The directory to test comes as the environment variable TEST_DIR.

# Use an "if" statement to check the value of TEST_DIR, then include commands
# necessary to test that implmentation. Note that this script is running in the
# top level directory, not in TEST_DIR. The commands must be followed with an
# "exit" statement to avoid dropping to the end, reporting TEST_DIR is
# unknown and returning success. The following is an example:
# if [ "$TEST_DIR" == "bbc_basic" ]; then
#   bbc_basic/run_tests
#   exit
# fi

# Go?
if [ "$TEST_DIR" == "go" ]; then
  go test ./go
  exit
fi
# Javascript?
if [ "$TEST_DIR" == "js" ]; then
  cd js && npm install && npm test
  exit
fi
# Ruby?
if [ "$TEST_DIR" == "ruby" ]; then
  rvm install 2.2.3
  source ~/.rvm/scripts/rvm
  rvm use 2.2.3
  gem install test-unit
  cd ruby && ruby test/plus_codes_test.rb
  exit
fi

if [ "$TEST_DIR" == "rust" ]; then
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  export PATH=$PATH:$HOME/.cargo/bin
  rustup update stable
  cd rust && rustup run stable cargo test
  exit
fi

echo "Unknown test directory: $TEST_DIR"
