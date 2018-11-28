# Open Location Code C API

This is the C implementation of the Open Location Code API.

# Building

For now we have a simple `Makefile`.  Usual targets work:
```
make clean
make all
make install
```

If you need to regenerate the lookup table, you can do:
```
make lug
```
and then check any changes that might need to be committed to git.

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

# Benchmarking

I wrote some benchmarks to compare the C and C++ implementations; they live in
the `benchmark` directory, and you can run them as:
```
cd benchmark
make clean all
make run
```

The benchmarks depend on you having built the C and C++ versions of the
library; adjust the `Makefile` if required for your case.  They are also very
simple minded: just run several operations, a bunch of times each, and measure
elapsed time.

Here are some results, showing three sets of values:
1. The C++ version.
2. The original C version.
3. The C version with an unrolled lookup table.

![Benchmark](benchmark/bm-20181128.png?raw=true "Benchmark")

The benchmarks were compiled with all default compiler flags and with `-O`, and
were executed on my laptop.  Here is some hardware and version information, for
full transparency:

```
$ sw_vers
ProductName:	Mac OS X
ProductVersion:	10.13.6
BuildVersion:	17G3025

$ c++ --version
Apple LLVM version 9.1.0 (clang-902.0.39.2)

$ /usr/sbin/system_profiler SPHardwareDataType
Model Name: MacBook Pro
Model Identifier: MacBookPro12,1
Processor Name: Intel Core i5
Processor Speed: 2,7 GHz
Number of Processors: 1
Total Number of Cores: 2
L2 Cache (per Core): 256 KB
L3 Cache: 3 MB
Memory: 16 GB
Boot ROM Version: 180.0.0.0.0
SMC Version (system): 2.28f7
```

# Authors

* The authors of the C++ implementation, on which this is based.
* [Gonzalo Diethelm](mailto:gonzalo.diethelm@gmail.com)
