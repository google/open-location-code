# Open Location Code JavaScript API
This is the JavaScript implementation of the Open Location Code API.

The library file is in `src/openlocationcode.js`. There is also a
minified version, and both are also available using the following CDNs:

* [jsDelivr](https://www.jsdelivr.com)
  * https://cdn.jsdelivr.net/openlocationcode/latest/openlocationcode.js
  * https://cdn.jsdelivr.net/openlocationcode/latest/openlocationcode.min.js
* [cdnjs](https://cdnjs.com/)
  * https://cdnjs.cloudflare.com/ajax/libs/openlocationcode/1.0.3/openlocationcode.js
  * https://cdnjs.cloudflare.com/ajax/libs/openlocationcode/1.0.3/openlocationcode.min.js

## Releasing

Once changes have been made and merged, start a new PR:

* run `gulp minify` to update the minified Javascript in `src`.
* update the `version` tag in the `package.json` file

To update the CDNs, you will have to add a new release tag. Note that release
tags are applied globally to the repository, so if you are making a change
across multiple implementations, consider waiting until all are updated before
adding the release tag.

# Tests

Unit tests require [gulp](https://www.npmjs.com/package/gulp),
[karma](https://karma-runner.github.io) and
[jasmine](https://jasmine.github.io).

Execute the tests with `sh test/run_tests.sh`. This will install the
dependencies, run `eslint` and then run the tests as long as there were no
eslint errors.

Unit tests are automatically run on pull and push requests and visible at
https://github.com/google/open-location-code/actions.

# Examples

Example web pages illustrating converting map clicks with Open Location Code,
and using Googles Maps API to extend place codes to full codes are in the
`examples/` directory.

More examples are on [jsfiddle](https://jsfiddle.net/u/openlocationcode/fiddles/).

# Public Methods

The following are the four public methods and one object you should use. All the
other methods in the code should be regarded as private and not called.

## encode()

```javascript
OpenLocationCode.encode(latitude, longitude, codeLength) → {string}
```

Encode a location into an Open Location Code.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `latitude` | `number` | The latitude in signed decimal degrees. Values less than -90 will be clipped to -90, values over 90 will be clipped to 90. |
| `longitude` | `number` | The longitude in signed decimal degrees. This will be normalised to the range -180 to 180. |
| `codeLength` | `number` | The desired code length. If omitted, `OpenLocationCode.CODE_PRECISION_NORMAL` will be used. For precision `OpenLocationCode.CODE_PRECISION_EXTRA` is recommended. |

**Returns:**

The code for the location.

**Exceptions:**

If any of the passed values are not numbers, an exception will be thrown.

## decode()

```javascript
OpenLocationCode.decode(code) → {OpenLocationCode.CodeArea}
```

Decodes an Open Location Code into its location coordinates.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `code` | `string` | The code to decode. |

**Returns:**

The `OpenLocationCode.CodeArea` object.

**Exceptions:**

If the passed code is not a valid full code, an exception will be thrown.

## shorten()

```javascript
OpenLocationCode.shorten(code, latitude, longitude) → {string}
```

Remove characters from the start of an OLC code.

This uses a reference location to determine how many initial characters
can be removed from the OLC code. The number of characters that can be
removed depends on the distance between the code center and the reference
location.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `code` | `string` | The code to shorten. |
| `latitude` | `number` | The latitude of the reference location. |
| `longitude` | `number` | The longitude of the reference location. |

**Returns:**

The code, shortened as much as possible that it is still the closest matching
code to the reference location.

**Exceptions:**

If the code is not a valid full code, or the latitude or longitude are not
numbers, an exception will be thrown.

## recoverNearest()

```javascript
OpenLocationCode.recoverNearest(shortCode, referenceLatitude, referenceLongitude) → {string}
```

Recover the nearest matching code to a specified location.

This is the counterpart to `OpenLocationCode.shorten()`. This recovers the
nearest matching full code to the reference location.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `shortCode` | `string` | The code to recover. |
| `referenceLatitude` | `number` | The latitude of the reference location. |
| `referenceLongitude` | `number` | The longitude of the reference location. |

**Returns:**

The nearest matching full code to the reference location.

**Exceptions:**

If the short code is not valid, or the reference position values are not
numbers, an exception will be thrown.

## CodeArea

```javascript
OpenLocationCode.CodeArea(latitudeLo, longitudeLo, latitudeHi, longitudeHi, codeLength) → {OpenLocationCode.CodeAre}
```

The `OpenLocationCode.CodeArea` class is used to return the area represented by
a code. Because codes are areas, not points, this gives the coordinates of the
south-west and north-east corners, the center, and the length of the code.

You can convert from a code to an area and back again like this:

```javascript
var a = '796RWF8Q+WF';
var area = OpenLocationCode.decode(a);
var original_code = OpenLocationCode.encode(area.latitudeCenter, area.longitudeCenter, area.codeLength);
```

**Attributes:**

| Name | Type | Description |
|------|------|-------------|
| `latitudeLo` | `number` | The latitude of the south-west corner. |
| `longitudeLo` | `number` | The longitude of the south-west corner. |
| `latitudeHi` | `number` | The latitude of the north-east corner. |
| `longitudeHi` | `number` | The longitude of the north-east corner. |
| `latitudeCenter` | `number` | The latitude of the center. |
| `longitudeCenter` | `number` | The longitude of the center. |
| `codeLength` | `number` | The length of the code that generated this area. |
