# Plus Codes Specification

## Version history

All substantial changes changes to this document are listed here.

* Version 1.1.0 / 2021-06-04 / [William Entriken](https://github.com/fulldecent/)
  * Separate Plus Codes specification from [Open Location Code API specification](./Open Location Code API Specification.md)
  * Define one code for the North Pole at each code level
  * Define one code for the South Pole at each code level (breaking change, previously many codes included the South Pole)
  * Specify which code levels of full codes may be shortened to which code levels of short codes
  * Establish consistent wording/naming
* Version 1.0.0 / 2019-04-29 / [Doug Rinckes](https://github.com/drinckes), Google / Philipp Bunge, Google
  * Initial public release

## Area and bounds

A **Plus Code** represents a locus of coordinates ("**area**") with **bounds** on northern & southern parallels and western & eastern meridians. This area includes exactly the coordinates:

1. Inside (excluding) the bounds;
2. On the western bound between (excluding) the northern and southern bounds;
3. (If the northern bound is 90° N and the western bound is 0° W) the North Pole (i.e. the point at 90° N);
4. (If the southern bound is 90° S and the western bound is 0° W) the South Pole (i.e. the point at 90° S); and
5. (If the southern bound is not 90° S) on the southern bound from (including) the western bound to (excluding) the eastern bound.

This specification references latitudes and longitudes on Earth under [WGS 84](https://earth-info.nga.mil), which is the standard used by the Global Positioning System. If another geodetic is used, that context MUST be agreed between the producer and consumer of a Plus Code.

The **center** of a Plus Code is defined as the arithmetic mean of its bound's parallels and meridians.

## Precision

Plus Codes are characterized by their **code length**. This specifies the distance between the northern & southern bounds and the western & eastern bounds. Plus codes MUST use one of these code lengths:

| Code length | North-south distance | West-east distance | Longest edge |
| :---------: | -------------------- | ------------------ | :----------: |
|      2      | 20 degrees           | 20 degrees         |  < 2300 km   |
|      4      | 1 degrees            | 1 degrees          |   < 120 km   |
|      6      | 1/20 degrees         | 1/20 degrees       |   < 5.6 km   |
|      8      | 1/400 degrees        | 1/400 degrees      | < 280 meters |
|     10      | 1/8000 degrees       | 1/8000 degrees     | < 14 meters  |
|     11      | 1/40000 degrees      | 1/32000 degrees    |  < 4 meters  |
|     12      | 1/200000 degrees     | 1/128000 degrees   |   < 90 cm    |
|     13      | 1/1e6 degrees        | 1/512000 degrees   |   < 22 cm    |
|     14      | 1/5e6 degrees        | 1/2.048e6 degrees  |    < 6 cm    |
|     15      | 1/2.5e7 degrees      | 1/8.192e7 degrees  |   < 14 mm    |

## Formatting

A Plus Code consists of two or more **significant digits**, zero or more **padding characters** and exactly one **format separator**. Plus Code formatting has been selected to reduce writing errors and prevent spelling words.

There are eight **digit places** to the left of the **format separator** and seven to the right:

<kbd>1</kbd><kbd>2</kbd><kbd>3</kbd><kbd>4</kbd><kbd>5</kbd><kbd>6</kbd><kbd>7</kbd><kbd>8</kbd><kbd>+</kbd><kbd>9</kbd><kbd>10</kbd><kbd>11</kbd><kbd>12</kbd><kbd>13</kbd><kbd>14</kbd><kbd>15</kbd>

Plus Codes SHALL NOT be formatted differently for right-to-left languages. This avoids ambiguity.

A significant digit represents a numeric value as:

| Value | 0    | 1    | 2    | 3    | 4    | 5    | 6    | 7    | 8    | 9    | 10   | 11   | 12   | 13   | 14   | 15   | 16   | 17   | 18   | 19   |
| ----- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| Digit | 2    | 3    | 4    | 5    | 6    | 7    | 8    | 9    | C    | F    | G    | H    | J    | M    | P    | Q    | R    | V    | W    | X    |

The padding character is defined as the zero ("0") character ([U+0030](http://unicode.org/charts/PDF/U0000.pdf)).

The format separator is defined as the plus ("+") character ([U+002B](http://unicode.org/charts/PDF/U0000.pdf)).

## Encoding

A Plus Code uses significant digits to encode its southern and western bounds. The significant digits of a Plus Code represent latitude (north) and then longitude (east) offsets from the starting location 90° S, 180° W. 

A significant digit in digit places 1, 3, 5, 7 and 9 represents an offset north equal to the north-south distance for that code length (find the code length for one more than the digit place in the code length table above) multiplied by the significant digit value.

A significant digit in digit places 2, 4, 6, 8 and 10 represents an offset east equal to the west-east distance for that code length multiplied by the significant digit value.

A significant digit in places 11 and higher represents:

* an offset north equal to the north-south distance for that code length multiplied by (the significant digit value divided by four and rounded down)
* an offset east equal to the west-east distance for that code length multiplied by (the significant digit value modulo 4)

<kbd>N</kbd><kbd>E</kbd><kbd>N</kbd><kbd>E</kbd><kbd>N</kbd><kbd>E</kbd><kbd>N</kbd><kbd>E</kbd><kbd>+</kbd><kbd>N</kbd><kbd>E</kbd><kbd>X</kbd><kbd>X</kbd><kbd>X</kbd><kbd>X</kbd><kbd>X</kbd>

:information_source: Note that latitudes greater than 90° N do not exist and therefore the digit place 1 MUST only have values 0–8. Likewise, digit place 2 MUST only have values 0–17.

## Full code

A **full code** Plus Code is globally usable and requires no other reference to interpret.

Every full code MUST include significant digits in digit places 1 up through the code length. If the code length is less than 8, then the padding character is placed in digit places after the last significant digit up to and including the 8th digit place. The format separator is added after the 8th digit place.

Therefore, the set of full codes exactly matches the [Perl Compatible Regular Expression](http://pcre.org):

````perl
/^[2-9C][2-9CFGHJMPQRV](0{6}\+|[2-9CFGHJMPQRVWX]{2}(0000\+|[2-9CFGHJMPQRVWX]{2}(00\+|[2-9CFGHJMPQRVWX]{2}\+([2-9CFGHJMPQRVWX]{2,7})?)))$/
````

## Short code

A **short code** Plus Code is meaningful only when the producer and consumer of the Plus Code agree on the approximate latitude and longitude of a **reference location**. A short code can be easier to use and remember than a full code.

Plus Codes with code length less than 8 SHALL NOT be represented as short codes.

The latitudinal distance (in degrees) and longitudinal distance (in degrees) between the Plus Code area's center and the reference location determines which digit places can be omitted in the short code representation:

* If both distances are less than 10 degrees, digit places 1–2 MAY be omitted.
* If both distances are less than 0.5 degrees, digit places 1–2 or 1–4 MAY be omitted.
* If both distances are less than 1/40 degrees, digit places 1–2, 1–4 or 1–6 MAY be omitted.

A short code represents the unique full code Plus Code nearest (latitudinal distance + longitudinal distance) to the reference location.

:information_source: Note that omitted digits places of a short code will not necessarily be the same as the reference location.

Therefore, the set of short code representations exactly matches the Perl Compatible Regular Expression:

```perl
/^([2-9CFGHJMPQRVWX]{2})?([2-9CFGHJMPQRVWX]{2})?[2-9CFGHJMPQRVWX]{2}\+([2-9CFGHJMPQRVWX]{2,7})?$/
```
