# dart library for Open Location Code

## Formatting

Code must be formatted using `dartfmt`:

```
dartfmt --fix --overwrite lib/* lib/src/* test/*
```

The TravisCI test will check, and will fail the tests if any files need
formatting.

## Testing

To test the dart version first download the dart sdk from
[Dart main site](http://www.dartlang.org) and run this from the repository root
directory:

```
~/open-location-code$ cd dart && pub run test
```
