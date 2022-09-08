# Python Library

This is the Python Open Location Code library. It is tested for both python 2.7
and python 3.6.

## Installing the library

The python library is available on PyPi. You can install it using pip:

```
pip install openlocationcode
```

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


## Releasing to PyPi

We release the python library to PyPi so users can install it using pip.

Pre-reqs:

```
pip install setuptools
pip install twine
```

To release a new version to PyPi, make sure you update the version number in setup.py. Then run:

```
python setup.py sdist
twine upload dist/*
```

Make sure any older versions are cleared out from dist before uploading. twine will prompt you for your PyPi credentials, which will need to be a collaborator on the project.
