# Open Location Code Specification

## Input values

Open Location Code encodes two numbers into a single, short string.

The latitude and longitude should be WGS84 values. If other datums are used it must be stated and made clear that these will produce different locations if plotted.

## Character Set

The following defines the valid characters in an Open Location Code. Sequences that contain other characters are by definition not valid Open Location Codes.

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
1. Add 90 to the latiude, multiply the fractional part by 2.5e7 and take the integer part as latitude.
1. Add 180 to the longitude, multiply the fractional part by 8.192e6 and take the integer part as longitude.
1. Take the integer part of latitude modulus 5. Multiply that by 4, and add the integer part of the longitude modulus 4.
1. Prefix the existing code with the symbol with the above value.
1. Divide longitude by four and latitude by five.
1. Repeat from step 2 four more times.

### Code length

The minimum valid length of an Open Location Code is two digits.
The maximum length of an Open Location Code is 15 digits.

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
(The north-east corner and center coordinates can be obtained by adding the precison values.)

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

## Library Implementation Requirements

Open Location Code library implementations must provide:
* a method to convert a latitude and longitude into a 10 digit Open Location Code
* a method to decode a 10 digit Open Location Code into, at a minimum, the latitude and longitude of the south-west corner and the height and width
* a method to determine if a string is a valid sequence of Open Location Code characters
* a method to determine if a string is a valid full Open Location Code
* decode and validation methods must not be case-sensitive

Open Location Code library implementations can provide:
* a method to convert a latitude and longitude into any valid length Open Location Code
* a method to decode any valid length Open Location Code, providing additional information such as center coordinates
* a method to to convert a valid Open Location Code into a short code, given a reference location
* a method to recover a full Open Location Code from a short code and a reference location.
* a method to determine if a string is a valid short Open Location Code

