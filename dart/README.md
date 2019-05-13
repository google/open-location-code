# dart library for Open Location Code

## Formatting

Code **must** be formatted using `dartfmt`.

To format your files, just run `format_check.sh` or:

```
dartfmt --fix --overwrite .
```

The TravisCI test **will fail if any files need formatting**.

## Hints

The TravisCI test uses `dartanalyzer` to check the library for improvements. IF
any are found the TravisCI tests **will fail**.

## Testing

To test the dart version first download the dart sdk from
[Dart main site](http://www.dartlang.org) and run this from the repository root
directory:

```
~/open-location-code$ cd dart && pub run test
```
