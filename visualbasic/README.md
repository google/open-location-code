
# VBA Open Location Code Library

This is an implementation of the Open Location Code library in VBA, Visual Basic
for Applications.

> With a simple change it will work in OpenOffice and LibreOffice. See below.

The intent is to provide the core functions of encoding, decoding, shorten and
recovery to spreadsheet and other applications.

## Function Description

### Encoding

```
OLCEncode(latitude, longitude [, length])
```

This returns the Open Location Code for the passed latitude and longitude (in
decimal degrees).

If the `length` parameter is not specified, the standard
precision length (`CODE_PRECISION_NORMAL`) will be used. This provides an area
that is 1/8000 x 1/8000 degree in size, roughly 14x14 meters. If
`CODE_PRECISION_EXTRA` is specified as `length`, the area of the code will be
roughly 2x3 meters.

### Decoding

Two decoding methods are provided. One returns a data structure, the other
returns an array and is more suited to use within a spreadsheet.

```
OLCDecode(code)
```

This decodes the passed Open Location Code, and returns an `OLCArea` data
structure, which has the following fields:

* `latLo`: The latitude of the south-west corner of the code area.
* `lngLo`: The longitude of the south-west corner of the code area.
* `latCenter`: The latitude of the center of the code area.
* `lngCenter`: The longitude of the center of the code area.
* `latHi`: The latitude of the north-east corner of the code area.
* `lngHi`: The longitude of the north-east corner of the code area.
* `codeLength`: The number of digits in the code.

```
OLCDecode2Array(code)
```

This returns an array of the fields from the `OLCArea` data structure, in the
following order:

`latLo`, `lngLo`, `latCenter`, `lngCenter`, `latHi`, `lngHi`, `codeLength`

### Shortening And Recovery

The codes returned by `OLCEncode` are globally unique, but often locally unique
is sufficient. For example, 796RWF8Q+WF can be shortened to WF8Q+WF, relative
to Praia, Cape Verde.

This works because 796RWF8Q+WF is the nearest match to the location.

```
OLCShorten(code, latitude, longitude)
```

This removes as many digits from the code as possible, so that it is still the
nearest match to the passed location.

> Even if six or more digits can be removed, we suggest only removing four so
that the codes are used consistently.

```
OLCRecoverNearest(code, latitude, longitude)
```

This uses the specified location to extend the short code and returns the
nearest matching full length code.

## Loading Into Excel

> Tested using Microsoft Excel for Mac 2011 version 14.6.6

1. Start Excel
2. Select the menu option Tools > Macro > Visual Basic Editor
3. After the project window opens, select the menu option File > Import File
and import the `OpenLocationCode.bas` file. This will add the functions to the
current workbook.

After importing, go back to the workbook, and run the self checks with:

1. Select menu option Tools > Macro > Macros...
2. In the Macro name: field type 'TestOLCLibrary' (it should be listed in the
box) and click Run
3. If successful, it will display a message window saying `All tests pass`

If `TestOLCLibrary` isn't listed, you may have imported the functions into
another workbook.

## Loading Into OpenOffice/LibreOffice

> Tested using LibreOffice version 4.2.8.2

To add the library to a OpenOffice or LibreOffice spreadsheet, follow these
steps (this example uses LibreOffice):

1. Select the menu option Tools > Macros > Organize Macros > LibreOffice Basic
2. In the Macro From panel, select the spreadsheet to add the library to.
3. Click New, enter a name for the module (e.g. OpenLocationCode), and press
OK. It will then display the macro editor.
4. Paste the full file into the editor, replacing the existing contents.
5. Uncomment the line to enable VBA compatibility:
```
Option VBASupport 1
```
That's it. Save the file. You can now use the functions above in your
spreadsheet!

## Reporting Issues

If the self tests fail, copy the error message or take a
screen shot and [log an issue](https://github.com/google/open-location-code/issues/new?labels=visualbasic&assignee=drinckes).

If you have any requests or suggestions on how to improve the code, either
log an issue using the link above, or send us a pull request.
