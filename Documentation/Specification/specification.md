# Open Location Code Specification

## Input values

Open Location Code encodes two numbers, latitude and longitude, in degrees, into a single, short string.

The latitude and longitude should be WGS84 values. If other datums are used it must be stated and made clear that these will produce different locations if plotted.

## Character Set

The following defines the valid characters in a Plus Code. Sequences that contain other characters are by definition not valid Open Location Code.

### Digits

Open Location Code symbols have been selected to reduce writing errors and prevent accidentally spelling words.
Here are the digits, shown with their numerical values:

|Symbol|2|3|4|5|6|7|8|9|C|F|G|H|J|M|P|Q|R|V|W|X|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Value|0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|

### Format Separator

The "+" character (U+002B) is used as a non-significant character to aid formatting.

### Padding Character

The "0" character (U+0030) is used as a padding character before the format separator.

## Encoding

Code digits and ordering do not change in right-to-left (RTL) languages.

The latitude number must be clipped to be in the range -90 to 90.

The longitude number must be normalised to be in the range -180 to 180.

### Most significant 10 digits

Summary:
Add 90 to latitude and 180 to longitude to force them into positive ranges.
Encode both latitude and longitude into base 20, using the symbols above, for five digits each i.e. to a place value of 0.000125.
Starting with latitude, interleave the digits.

The following provides an algorithm to encode the values from least significant digit to most significant digit:
1. Add 90 to the latitude and add 180 to the longitude, multiply both by 8000 and take the integer parts as latitude and longitude respectively
1. Prefix the existing code with the symbol that has the integer part of longitude modulus 20
1. Prefix the existing code with the symbol that has the integer part of latitude modulus 20
1. Divide both longitude and latitude by 20
1. Repeat from step 2 four more times.

### Least significant five digits

This differs from the above method in that each step produces a single character.
This encodes latitude into base five and longitude into base four, and then combines the digits for each position together.

The following provides an algorithm to encode the values from least significant digit to most significant digit:
1. Add 90 to the latitude, multiply the fractional part by 2.5e7 and take the integer part as latitude.
1. Add 180 to the longitude, multiply the fractional part by 8.192e6 and take the integer part as longitude.
1. Take the integer part of latitude modulus 5. Multiply that by 4, and add the integer part of the longitude modulus 4.
1. Prefix the existing code with the symbol with the above value.
1. Divide longitude by four and latitude by five.
1. Repeat from step 2 four more times.

### Code length

The minimum valid length of a Plus Code is two digits.
The maximum length of a Plus Code is 15 digits.

Below 10 digits, only even numbers are valid lengths.

The default length for most purposes is 10 digits.

### Formatting

The format separator must be inserted after eight digits.
If the requested code length is fewer than eight digits, the remaining digits before the format separator must consist of the padding character.

### Code precision

The following table gives the precision of the valid code lengths in degrees and in meters. Where the precisions differ between latitude and longitude both are shown:

| Code length | Precision in degrees | Precision        |
| :---------: | :------------------: | :--------------: |
| 2           | 20                   | 2226 km          |
| 4           | 1                    | 111.321 km       |
| 6           | 1/20                 | 5566 meters      |
| 8           | 1/400                | 278 meters       |
| 10          | 1/8000               | 13.9 meters      |
| 11          | 1/40000 x 1/32000    | 2.8 x 3.5 meters |
| 12          | 1/200000 x 1/128000  | 56 x 87 cm       |
| 13          | 1/1e6 x 1/512000     | 11 x 22 cm       |
| 14          | 1/5e6 x 1/2.048e6    | 2 x 5 cm         |
| 15          | 1/2.5e7 x 1/8.192e6  | 4 x 14 mm        |

NB: This table assumes one degree is 111321 meters, and that all distances are calculated at the equator.

## Decoding

The coordinates obtained when decoding are the south-west corner.
(The north-east corner and center coordinates can be obtained by adding the precision values.)

This implies that the north-east coordinates are not included in the area of the code, with the exception of codes whose northern latitude is 90 degrees.

## Short Codes

Short codes are used relative to a reference location.
They allow the code part to be shorter, easier to use and easier to remember.

Short codes have at least two and a maximum of six digits removed from the beginning of the code.
The resulting code must include the "+" character (the format separator).

Codes that include padding characters must not be shortened.

Digits can be removed from the code, while the precision of the position is more than twice the maximum of the latitude or longitude offset between the code center and the reference location.
Recovery of the original code must meet the same criteria.

For example, 8FVC9G8F+6W has the center 47.365562,8.524813. The following table shows what it can be shortened to, relative to various locations:

| Reference Location | Latitude offset | Longitude offset | Twice max offset | Code can be shortened to |
| ------------------ | --------------: | ---------------: | ---------------: | -----------------------: |
| 47.373313,8.537562 | 0.008           | 0.013            | 0.025            | 8F+6W                    |
| 47.339563,8.556687 | 0.026           | 0.032            | 0.064            | 9G8F+6W                  |
| 47.985187,8.440688 | 0.620           | 0.084            | 1.239            | VC9G8F+6W                |
| 38.800562,-9.064937| 0.620           | 8.565            | 17.590           | 8FVC9G8F+6W              |

Note: A code that has been shortened will not necessarily have the same initial four digits as the reference location.

### Generating Short Codes

Being able to say _WF8Q+WF, Praia_ is significantly easier than remembering and using _796RWF8Q+WF_.
With that in mind, how do you choose the locality to use as a reference?

Ideally, you need to use both the bounding box of the locality, as well as its center point.

Given a global code, _796RWF8Q+WF_, you can eliminate the first **four** digits of the code if:
 * The center point of the feature is within **0.4** degrees latitude and **0.4** degrees longitude
 * The bounding box of the feature is less than **0.8** degrees high and wide.

(These values are chosen because a four digit Plus Code is 1x1 degrees.)

If there is no suitable locality close enough or small enough, you can eliminate the first **two** digits of the code if:
 * The center point of the feature is within **8** degrees latitude and **8** degrees longitude
 * The bounding box of the feature is less than **16** degrees high and wide.

(These values are chosen because a two digit Plus Code is 20x20 degrees.)

The values above are slightly smaller than the maximums to allow for different geocoder backends placing localities in slightly different positions.
Although they could be increased there will be a risk that a shortened code will recover to a different location than the original, and people misdirected.

Note: Usually your feature will be a town or city, but you could also use geographical features such as lakes or mountains, if they are the best local reference.
If a settlement (such as neighbourhood, town or city) is to be used, you should choose the most prominent feature that meets the requirements, to avoid using obscure features that may not be widely known.
(Basically, prefer city or town over neighbourhood.)

## API Requirements

The following public methods should be provided by any Open Location Code implementation, subject to minor changes caused by language conventions.

Note that any method that returns a Plus Code should return upper case characters.

Methods that accept Plus Codes as parameters should be case insensitive.

Capitalisation should follow the language convention, for example the method `isValid` in golang would be `IsValid`.

Errors should be returned following the language convention. For example exceptions in Python and Java, `error` objects in golang.

### `isValid`

The `isValid` method takes a single parameter, a string, and returns a boolean indicating whether the string is a valid Plus Code.

### `isShort`

The `isShort` method takes a single parameter, a string, and returns a boolean indicating whether the string is a valid short Plus Code.

 See [Short Codes](#short-codes) above.

### `isFull`

Determines if a code is a valid full (i.e. not shortened) Plus Code.

Not all possible combinations of Open Location Code characters decode to valid latitude and longitude values.
This checks that a code is valid and that the resulting latitude and longitude values are legal.
Full codes must include the format separator character and it must be after eight characters.

### `encode`

Encode a location into a Plus Code.
This takes a latitude and longitude and an optional length.
If the length is not specified, a code with 10 digits (and the format separator character) will be returned.

### `decode`

Decodes a Plus Code into the location coordinates.
This method takes a string.
If the string is a valid full Plus Code, it returns:
- the latitude and longitude of the SW corner of the bounding box;
- the latitude and longitude of the NE corner of the bounding box;
- the latitude and longitude of the center of the bounding box;
- the number of digits in the original code.

### `shorten`

Passed a valid full Plus Code and a latitude and longitude this removes as many digits as possible (up to a maximum of six) such that the resulting code is the closest matching code to the passed location.
A safety factor may be included.

If the code cannot be shortened, the original full code should be returned.

Since the only really useful shortenings are removing the first four or six characters, methods such as `shortenBy4` or `shortenBy6` could be provided instead.

### `recoverNearest`

This method is passed a valid short Plus Code and a latitude and longitude, and returns the nearest matching full Plus Code to the specified location.
