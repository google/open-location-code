# Python Library

This is the Python Open Location Code library. It is tested for python 3,
but should work with python 2 as well.

## Formatting

Code must be formatted according to the
(Google Python Style Guide)[http://google.github.io/styleguide/pyguide.html].

You can format your code automatically using
[YAPF](https://github.com/google/yapf/).

### Installing YAPF

Ensure you have pip installed:

```
wget https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py
```

Then install YAPF:

```
pip install --user yapf
```

### Formatting code

To see if the files need formatting, look at the TravisCI test output, or run:

```
$HOME/.local/bin/yapf --diff openlocationcode.py openlocationcode_test.py
```

If the files need formatting, run:

```
$HOME/.local/bin/yapf --in-place openlocationcode.py openlocationcode_test.py

```


## Testing

Run the unit tests and benchmarks with:

```
bazel test python:openlocationcode_test
```

If the tests fail, or if the code needs formatting, the integration tests
will fail.
