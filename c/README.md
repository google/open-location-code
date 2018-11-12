# Open Location Code C API

This is the C implementation of the Open Location Code API.

# Building

For now we have a simple `Makefile`.  Usual targets work:
```
make clean
make all
make install
```

# Examples

See `example.c` for how to use the library. To run the example, use:
```
make example && ./example
```

# Testing

To test the library, use:
```
make test
```

The tests use the CSV files in the parent's `test_data` folder.

# Authors

* The authors of the C++ implementation, on which this is based.
* [Gonzalo Diethelm](mailto:gonzalo.diethelm@gmail.com)
