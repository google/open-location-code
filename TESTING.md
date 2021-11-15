# Testing
The preferred mechanism for testing is using the [Bazel](https://bazel.build/) build system. This uses files called `BUILD` ([example](https://github.com/google/open-location-code/blob/master/BUILD) to provide rules to build code and run tests).

Create a `BUILD` file in your code directory with a [test rule](https://bazel.build/versions/master/docs/test-encyclopedia.html).
You can then test your code by running:

```sh
bazel test <dir>:<rule>
```

All tests can be run with:

```sh
bazel test ...:all
```

## Automated Integration Testing
On pushes and pull requests changes are tested via GitHub Actions. You can see the current test status in the [Actions tab](https://github.com/google/open-location-code/actions/workflows/main.yml?query=branch%3Amain).

The testing configuration is controlled by the [`.github/workflows/main.yml`](.github/workflows/main.yml) file.

### [.github/workflows/main.yml](.github/workflows/main.yml)
This file defines each language configuration to be tested.

Some languages can be tested natively, others are built and tested using bazel BUILD files.

An example of a language being tested natively is go:

```
   # Go implementation. Lives in go/
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
      run: go test ./${OLC_PATH}
```

This defines the language, uses the `1.17` version, sets an environment variable with the path and then runs the testing command `go test ./go`.

An example of a language using bazel is Python:

```
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
```

Bazel is pre-installed on GitHub-hosted runners which are used to run CI, so there's no need to install it. This example also shows how to test with multiple versions of a language.

### Adding Your Tests

Simply add a new section to the `.github/workflows/main.yml` file with the appropriate language, and either the native test command or call `bazel test` like the other examples. More information about GitHub actions can be found in the [documentation](https://docs.github.com/en/actions/quickstart).
