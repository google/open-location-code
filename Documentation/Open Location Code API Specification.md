# Open Location Code API Reference Specification

## Version history

All substantial changes changes to this document are listed here.

* Version 1.1.0 / 2021-06-04 / [William Entriken](https://github.com/fulldecent/)
  * Update to match nomenclature in [Plus Codes specification](./Plus%20Codes%20Specification.md)
  * Separate REQUIRED and OPTIONAL public methods
  * Specify the number of significant digits that a short code Plus Code may omit

- Version 1.0.0 / 2014-10-27 / [Doug Rinckes](https://github.com/drinckes), Google / Philipp Bunge, Google
  - Initial public release

## REQUIRED public methods

An implementation of the Open Location Code API SHALL implement these REQUIRED methods:

| Method name          | Input(s)                        | Output(s)                                                    |
| -------------------- | ------------------------------- | ------------------------------------------------------------ |
| `isFull`             | Plus Code string                | True if this is a long code Plus Code, false otherwise       |
| `encodeWithLength10` | Latitude, longitude             | The Plus Code with code length 10 with area that contains the specified coordinates |
| `decodeWithLength10` | Plus Code string with length 10 | The southern parallel and western meridian for the Plus Code area |

Implementations are RECOMMENDED to use the method names above.

Note: it is possible to implement `isFull` using a Perl Compatible Regular Expression, see the Plus Code specification.

## OPTIONAL public methods

An implementation MAY implement these functions.

| Method name        | Input(s)                                                     | Output(s)                                                    |
| ------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `isValid`          | Plus Code string                                             | True if this is a Plus Code (full code or short code), false otherwise |
| `isShort`          | Plus Code string                                             | True if this is a short code Plus Code, false otherwise      |
| `encodeWithLength` | Latitude, longitude, code length                             | The Plus Code with specified code length with area that contains the specified coordinates |
| `decode`           | Plus Code string (full code or short code)                   | The southern parallel and western meridian for the Plus Code area, and the code length of the Plus Code |
| `shorten`          | Full code Plus Code, reference location latitude and longitude | The short code Plus Code representing the input where all significant digits that are allowed to be omitted are omitted; or if no digits are allowed to be omitted then the input is returned |
| `recoverNearest`   | Short code Plus Code, reference location latitude and longitude | The unique full code Plus Code nearest (latitudinal distance + longitudinal distance) to the reference location |

Implementations are RECOMMENDED to use the method names above.

An implementation MAY implement `shorten` using separate `shortenBy4` and `shortenBy6` methods.

Note: it is possible to implement `isValid` and `isShort` using a Perl Compatible Regular Expression, see the Plus Code specification.

## REQUIREMENTS for all public methods

Implementations MUST follow these REQUIREMENTS for all public methods:

* Plus Code Inputs MUST treat non-upper-case inputs as if they were upper case.
* Plus Code outputs MUST be uppercase and conform to the [Plus Codes Specification].
* Latitude inputs MUST treat a latitude greater than 90° N as if it were the North Pole (i.e. at 90° N).
* Latitude inputs MUST treat a latitude lower than 90° S as if it were the South Pole (i.e. at 90° S).
* Longitude inputs MUST treat values outside the range from (including) 180° W to (excluding) 180° E as if they were the equivalent longitude in this range.
* Longitude inputs MUST NOT cause runtime performance linearly dependent on the longitude. E.g. use `LONGITUDE % 360`, not `WHILE (LONGITUDE > 180) LONGITUDE -= 360`.

## OPTIONAL notes for all public methods

Implementations MAY follow these specifications for all public methods.

* Every public method that returns a southern parallel and western meridian may also return the northern parallel, the eastern meridian as well as the center. See definition of center in the Plus Codes specification.

## Implementation RECOMMENDATION

An implementation MAY use the following RECOMMENDATIONS.

- If latitude is 90° N or higher, directly return the Plus Code `C2X2X2X2+X2RRRRR`, truncated as necessary.
- If latitude is 90° S or lower, directly return the Plus Code `22222222+2222222`, truncated as necessary.
- If longitude is outside [180° W, 180° E), use a single modular calculation to enter the correct range.
- If your platform supports floating point numbers with mantissa of at least 35 bits (e.g. IEEE 754 double precision or better), then:
  - Multiply the input latitude by 2.5e7 and the longitude by 8.192e7 one time. This prevents inaccurate floating point math resulting from repeated multiplications/divisions. All remaining calculations can be done using base-20, base-4 and base-5 math on this integer value.
- If your platform only supports floating point numbers with mantissa up to 24 bits (e.g. IEEE 754 single precision) then your application will not produce accurate results in all cases for Plus Codes with code length greater than 12. This should produce a warning or error if greater than this precision is requested.

## References

- [Plus Codes specification](./Plus%20Codes%20Specification.md)
