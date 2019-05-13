# Python Library

This is the Python Open Location Code library. It is tested for both python 2.7
and python 3.6.

## Formatting

Code must be formatted according to the
[Google Python Style Guide](http://google.github.io/styleguide/pyguide.html).

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

To format your files, just run:

```
bash format_check.sh
```

If you just want to see the changes, you can run `python -m yapf --diff *py`

This script runs as part of the TravisCI tests - if files need formatting it
will display the required changes **and fail the test**.


## Testing

Run the unit tests and benchmarks locally with:

```
bazel test python:openlocationcode_test
```

