# Testing
The preferred mechanism for testing is using the [Bazel](https://bazel.build/)
build system. This uses files called `BUILD` ([example](https://github.com/google/open-location-code/blob/master/BUILD)
to provide rules to build code and run tests).

Create a `BUILD` file in your code directory with a [test rule](https://bazel.build/versions/master/docs/test-encyclopedia.html).
You can then test your code by running:

```sh
blaze test <dir>:<rule>
```

All tests can be run with:

```sh
blaze test ...:all
```

## Automated Integration Testing
Changes are sent to [Travis CI](https://travis-ci.org)
for integration testing after pushes, and you can see the current test status
[here](https://travis-ci.org/google/open-location-code).

The testing configuration is controlled by the [`travis.yml`](.travis.yml) file.

### [.travis.yml](.travis.yml)
This file defines each language configuration to be tested.

Some languages can be tested natively, others are built and tested using bazel BUILD files.

An example of a language being tested natively is go:

```
    # Go implementation. Lives in go/
    - language: go
      go: stable
      env: OLC_PATH=go
      script:
        - go test ./go
```

This defines the language, uses the `stable` version, sets an environment variable
with the path and then runs the testing command `go test ./go`.

An example of a language using bazel is Python:

```
    # Python implementation. Lives in python/, tested with bazel.
    - language: python
      python: 2.7
      env: OLC_PATH=python
      script:
        - wget -O install.sh "https://github.com/bazelbuild/bazel/releases/download/0.5.3/bazel-0.5.3-installer-linux-x86_64.sh"
        - chmod +x install.sh
        - ./install.sh --user && rm -f install.sh
        - ~/bin/bazel test --test_output=all ${OLC_PATH}:all
```

The big difference is that the bazel software must be downloaded and
installed before running the test command: 
`~/bin/bazel test --test_output=all ${OLC_PATH}:all`.

Note that this configuration tests python version 2.7. If you want to test multiple
versions, you will need to define **another** language entry with the version
specified. (You cannot specify multiple versions in a single language entry.)

### Adding Your Tests

Simply add a new section to the `.travis.yml` file with the appropriate language,
and either the native test command or install the bazel software and call the
`bazel test` like the other examples.
