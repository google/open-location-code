// A separator used to break the code into two parts to aid memorability.
pub const SEPARATOR: char = '+';

// The number of characters to place before the separator.
pub const SEPARATOR_POSITION: usize = 8;

// The character used to pad codes.
pub const PADDING_CHAR: char = '0';
pub const PADDING_CHAR_STR: &str = "0";

// The character set used to encode the values.
pub const CODE_ALPHABET: [char; 20] = [
    '2', '3', '4', '5', '6', '7', '8', '9', 'C', 'F', 'G', 'H', 'J', 'M', 'P', 'Q', 'R', 'V', 'W',
    'X',
];

// The base to use to convert numbers to/from.
pub const ENCODING_BASE: usize = 20;

// The maximum value for latitude in degrees.
pub const LATITUDE_MAX: f64 = 90f64;

// The maximum value for longitude in degrees.
pub const LONGITUDE_MAX: f64 = 180f64;

// Minimum number of digits to process for Plus Codes.
pub const MIN_CODE_LENGTH: usize = 2;

// Maximum number of digits to process for Plus Codes.
pub const MAX_CODE_LENGTH: usize = 15;

// Maximum code length using lat/lng pair encoding. The area of such a
// code is approximately 13x13 meters (at the equator), and should be suitable
// for identifying buildings. This excludes prefix and separator characters.
pub const PAIR_CODE_LENGTH: usize = 10;

// Digits in the grid encoding..
pub const GRID_CODE_LENGTH: usize = 5;

// The resolution values in degrees for each position in the lat/lng pair
// encoding. These give the place value of each position, and therefore the
// dimensions of the resulting area.
pub const PAIR_RESOLUTIONS: [f64; 5] = [20.0f64, 1.0f64, 0.05f64, 0.0025f64, 0.000125f64];

// Number of columns in the grid refinement method.
pub const GRID_COLUMNS: usize = 4;

// Number of rows in the grid refinement method.
pub const GRID_ROWS: usize = 5;

// Minimum length of a code that can be shortened.
pub const MIN_TRIMMABLE_CODE_LEN: usize = 6;

// What to multiply latitude degrees by to get an integer value. There are three pairs representing
// decimal digits, and five digits in the grid.
pub const LAT_INTEGER_MULTIPLIER: i64 = (ENCODING_BASE
    * ENCODING_BASE
    * ENCODING_BASE
    * GRID_ROWS
    * GRID_ROWS
    * GRID_ROWS
    * GRID_ROWS
    * GRID_ROWS) as i64;

// What to multiply longitude degrees by to get an integer value. There are three pairs representing
// decimal digits, and five digits in the grid.
pub const LNG_INTEGER_MULTIPLIER: i64 = (ENCODING_BASE
    * ENCODING_BASE
    * ENCODING_BASE
    * GRID_COLUMNS
    * GRID_COLUMNS
    * GRID_COLUMNS
    * GRID_COLUMNS
    * GRID_COLUMNS) as i64;
