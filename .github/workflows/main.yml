name: CI
on: [push, pull_request, workflow_dispatch]
jobs:
  # C implementation. Lives in c/, tested with bazel.
  test-c:
    runs-on: ubuntu-latest
    env:
      OLC_PATH: c
    steps:
      - uses: actions/checkout@v2
      - name: test
        run: bazel test --test_output=all ${OLC_PATH}:all
      - name: check formatting
        run: cd ${OLC_PATH} && bash clang_check.sh
        
  # C++ implementation. Lives in cpp/, tested with bazel.
  test-cpp:
    runs-on: ubuntu-latest
    env:
      OLC_PATH: cpp
    steps:
      - uses: actions/checkout@v2
      - name: test
        run: bazel test --test_output=all ${OLC_PATH}:all
      - name: check formatting
        run: cd ${OLC_PATH} && bash clang_check.sh
        
  # Dart implementation. Lives in dart/.
  test-dart:
    runs-on: ubuntu-latest
    env:
      OLC_PATH: dart
    steps:
      - uses: actions/checkout@v2
      - uses: dart-lang/setup-dart@v1
      - name: test
        run: |
          cd ${OLC_PATH}
          pub get && pub run test
          bash checks.sh

  # Go implementation. Lives in go/. Tests fail if files have not been formatted with gofmt.
  test-go:
    runs-on: ubuntu-latest
    env:
      OLC_PATH: go
    steps:
    - uses: actions/checkout@v2
    - uses: actions/setup-go@v2
      with:
        go-version: 1.17
    - name: test
      run: |
        cd ${OLC_PATH}
        diff -u <(echo -n) <(gofmt -d -s ./)
        go test -bench=. ./ -v
    - name: test-gridserver
      run: |
        cd tile_server/gridserver
        go test ./ -v
        
  # Java implementation. Lives in java/, tested with bazel and maven.     
  test-java:
    runs-on: ubuntu-latest
    env:
      OLC_PATH: java
    strategy:
      matrix:
        java: [ '8', '11', '16', '17' ]
    name: test-java-${{ matrix.java }}
    steps:
      - uses: actions/checkout@v2
      - name: Setup java
        uses: actions/setup-java@v2
        with:
          distribution: 'temurin'
          java-version: ${{ matrix.java }}
      - name: test
        run: bazel test --test_output=all ${OLC_PATH}:all && cd ${OLC_PATH} && mvn package
        
  # Javascript Closure library implementation. Lives in js/closure, tested with bazel.  
  test-js-closure:
    runs-on: ubuntu-latest
    env:
      OLC_PATH: js/closure
    steps:
      - uses: actions/checkout@v2
      - name: test
        run: |
          bazel test ${OLC_PATH}:all
          cd js && npm install && ./node_modules/.bin/eslint closure/*js

  # Javascript implementation. Lives in js/.
  test-js:
    runs-on: ubuntu-latest
    env:
      OLC_PATH: js
    steps:
      - uses: actions/checkout@v2
      - name: test
        run: |
          cd ${OLC_PATH}
          bash checks.sh
          
  # Python implementation. Lives in python/, tested with bazel.
  test-python:
    runs-on: ubuntu-latest
    env:
      OLC_PATH: python
    strategy:
      matrix:
        python: [ '2.7', '3.6', '3.7', '3.8' ]
    name: test-python-${{ matrix.python }}
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python 
        uses: actions/setup-python@v2
        with:
          python-version: ${{ matrix.python }}
      - name: test
        run: bazel test --test_output=all ${OLC_PATH}:all
      - name: check formatting
        run: |
          cd ${OLC_PATH}
          pip install yapf
          DIFF=`python -m yapf --diff *py`
          if [ $? -eq 0 ]; then
            echo -e "Python files are correctly formatted"
            exit 0
          else 
            echo -e "Python files have formatting errors"
            echo -e "These must be corrected using format_check.sh"
            echo "$DIFF"
          fi
          exit 1
          
  # Ruby implementation. Lives in ruby/.
  test-ruby:
    runs-on: ubuntu-latest
    env:
      OLC_PATH: ruby
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '2.6'
      - name: test
        run: |
          gem install rubocop
          gem install test-unit
          cd ${OLC_PATH} && ruby test/plus_codes_test.rb
          rubocop --config rubocop.yml

  # Rust implementation. Lives in rust/.
  test-rust:
    runs-on: ubuntu-latest
    env:
      OLC_PATH: rust
    steps:
      - uses: actions/checkout@v2
      - name: test
        run: |
          cd ${OLC_PATH}
          cargo fmt --all -- --check
          cargo build
          cargo test -- --nocapture
