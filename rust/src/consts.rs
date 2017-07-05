// A separator used to break the code into two parts to aid memorability.
pub const SEPARATOR: char = '+';

// The number of characters to place before the separator.
pub const SEPARATOR_POSITION: usize = 8;

// The character used to pad codes.
pub const PADDING_CHAR: char = '0';
pub const PADDING_CHAR_STR: &'static str = "0";

// The character set used to encode the values.
pub const CODE_ALPHABET: [char; 20] = [
'2', '3', '4', '5', '6',
'7', '8', '9', 'C', 'F',
'G', 'H', 'J', 'M', 'P',
'Q', 'R', 'V', 'W', 'X',
];

// The base to use to convert numbers to/from.
pub const ENCODING_BASE: f64 = 20f64;

// The maximum value for latitude in degrees.
pub const LATITUDE_MAX: f64 = 90f64;

// The maximum value for longitude in degrees.
pub const LONGITUDE_MAX: f64 = 180f64;

// Maxiumum code length using lat/lng pair encoding. The area of such a
// code is approximately 13x13 meters (at the equator), and should be suitable
// for identifying buildings. This excludes prefix and separator characters.
pub const PAIR_CODE_LENGTH: usize = 10;

// The resolution values in degrees for each position in the lat/lng pair
// encoding. These give the place value of each position, and therefore the
// dimensions of the resulting area.
pub const PAIR_RESOLUTIONS: [f64; 5] = [
    20.0f64, 1.0f64, 0.05f64, 0.0025f64, 0.000125f64
];

// Number of columns in the grid refinement method.
pub const GRID_COLUMNS: f64 = 4f64;

// Number of rows in the grid refinement method.
pub const GRID_ROWS: f64 = 5f64;

// Minimum length of a code that can be shortened.
pub const MIN_TRIMMABLE_CODE_LEN: usize = 6;

