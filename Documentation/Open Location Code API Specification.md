# Open Location Code API Reference Specification

## Version history

All substantial changes changes to this document are listed here.

* Version 1.0.5 / 2021-06-04 / [William Entriken](https://github.com/fulldecent/)
  * Update to match nomenclature in [Plus Codes specification](./Plus Codes Specification.md)
  * Separate REQUIRED and OPTIONAL public methods
  * Specify the number of significant digits that a short code Plus Code may omit

- Version 1.0.0 / 2014-10-27 / [Doug Rinckes](https://github.com/drinckes), Google / Philipp Bunge, Google
  - Initial public release

## REQUIRED public methods

An implementation of the Open Location Code API SHALL implement all these REQUIRED methods:

* `isFull`
  * Input: a string (expecting a Plus Code string)
  * Output: a boolean, true if this is a long code Plus Code, false otherwise
  * Note: it is possible to implement using a Perl Compatible Regular Expression, see the Plus Code specification.
* `encodeWithLength10`
  * Input: and latitude and longitude
    * An input which has latitude greater than 90° N must be treated as if it were the North Pole (i.e. at 90° N).
    * An input which has latitude lower than 90° S must be treated as if it were the South Pole (i.e. at 90° S).
    * An input which has longitude outside the range from (including) 180° W to (excluding) 180° E, must be treated as if it were the equivalent longitude in this range.
  * Output: the Plus Code with code length 10 with area that contains the specified coordinates
  * Requirements:
    * The runtime of this function must not depend linearly on the longitude. E.g. use `LONGITUDE % 360`, not `WHILE (LONGITUDE > 180) LONGITUDE -= 360`.
* `decodeWithLength10`
  * Input: a string (expecting a full code Plus Code string with code length 10)
  * Output: the southern parallel and western meridian for the Plus Code area

## OPTIONAL public methods

An implementation MAY additionally provide these functions.

* `isValid`
  * Input: a string (expecting a Plus Code string)
  * Output: a boolean, true if this is a Plus Code (full code or short code), false otherwise
  * Note: it is possible to implement using a Perl Compatible Regular Expression, see the Plus Code specification.

* `isShort`
  * Input: a string (expecting a Plus Code string)
  * Output: a boolean, true if this is a short code Plus Code, false otherwise
  * Note: it is possible to implement using a Perl Compatible Regular Expression, see the Plus Code specification.

* `encodeWithLength`
  * Input: and latitude and longitude
  * Output: the Plus Code with specified code length with area that contains the specified coordinates
* `decode`
  * Input: a string (expecting a full code Plus Code string)
  * Output: the southern parallel and western meridian for the Plus Code area, and the code length of the Plus Code

* `shorten`
  * Input: a string (expecting a full code Plus Code string) and a reference location latitude and longitude
  * Output: the short code Plus Code representing the input full code Plus Code where all significant digits that are allowed to be removed are omitted; or if no digits are allowed to be omitted then the full code is returned
  * Note: an implementation MAY implement this public method using separate `shortenBy4` and `shortenBy6` methods.
* `recoverNearest`
  * Input: a string (expecting a short code Plus Code string) and a reference location latitude and longitude
  * Output: the unique full code Plus Code nearest (latitudinal distance + longitudinal distance) to the reference location

## Additional REQUIREMENTS for all public methods

Implementations MUST follow these REQUIREMENTS for all public methods.

* Every function input that accepts a string expecting a Plus Code MUST work on any case of string the same as the expected upper case strings.
* Every function output that produces a Plus Code MUST be in uppercase.

## Additional OPTIONS for all public methods

Implementations MAY follow these specifications for all public methods.

* Every function that returns a southern parallel and western meridian may also return the northern parallel, the eastern meridian as well as the center. See definition of center in the Plus Codes specification.

## Implementation RECOMMENDATION

An implementation MAY use the following RECOMMENDATIONS.

- If latitude is 90° N or higher, directly return the Plus Code `C2X2X2X2+X2RRRRR`, truncated as necessary.
- If latitude is 90° S or lower, directly return the Plus Code `22222222+2222222`, truncated as necessary.
- If longitude is outside [180° W, 180° E), use a single modular calculation to enter the correct range.
- If your platform supports floating point numbers with mantissa of at least 35 bits (e.g. IEEE 754 double precision or better), then:
  - Multiply the input latitude by 2.5e7 and the longitude by 8.192e7 one time. This prevents inaccurate floating point math resulting from repeated multiplications/divisions. All remaining calculations can be done using base-20, base-4 and base-5 math on this integer value.
- If your platform only supports floating point numbers with mantissa up to 24 bits (e.g. IEEE 754 single precision) then your application will not produce accurate results in all cases for Plus Codes with code length greater than 12. This should produce a warning or error if greater than this precision is requested.





## References

- Plus Codes specification / https://github.com/google/open-location-code/blob/main/Documentation/Plus%20Codes%20Specification.md







