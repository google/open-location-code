use consts::{
    CODE_ALPHABET, ENCODING_BASE, LATITUDE_MAX, LONGITUDE_MAX, PAIR_CODE_LENGTH, GRID_ROWS,
    GRID_COLUMNS,
};

use interface::encode;

use geo::Point;

pub fn code_value(chr: char) -> usize {
    for (i, c) in CODE_ALPHABET.iter().enumerate() {
        if chr == *c {
            return i;
        }
    }
    0
}

pub fn normalize_longitude(value: f64) -> f64 {
    let mut result: f64 = value;
    while result >= LONGITUDE_MAX {
        result = result - LONGITUDE_MAX * 2f64;
    }
    while result < -LONGITUDE_MAX{
        result = result + LONGITUDE_MAX * 2f64;
    }
    result
}

pub fn clip_latitude(latitude_degrees: f64) -> f64 {
    latitude_degrees.min(LATITUDE_MAX).max(-LATITUDE_MAX)
}

pub fn compute_latitude_precision(code_length: usize) -> f64 {
    if code_length <= PAIR_CODE_LENGTH {
        return ENCODING_BASE.powf((code_length as f64 / -2f64 + 2f64).floor())
    }
    ENCODING_BASE.powf(-3f64) / GRID_ROWS.powf(code_length as f64 - PAIR_CODE_LENGTH as f64)
}

pub fn prefix_by_reference(pt: Point<f64>, code_length: usize) -> String {
    let precision = compute_latitude_precision(code_length);
    let mut code = encode(
        Point::new(
            (pt.lng() / precision).floor() * precision,
            (pt.lat() / precision).floor() * precision
        ),
        PAIR_CODE_LENGTH
    );
    code.drain(code_length..);
    code
}

pub fn near(value: f64) -> bool {
    value.trunc() != (value + 0.0000000001f64).trunc()
}

pub fn narrow_region(digit: usize, lat: &mut f64, lng: &mut f64) {
    if digit == 0 {
        *lat /= ENCODING_BASE;
        *lng /= ENCODING_BASE;
    } else if digit < 10 {
        *lat *= ENCODING_BASE;
        *lng *= ENCODING_BASE;
    } else {
        *lat *= GRID_ROWS;
        *lng *= GRID_COLUMNS
    }
    if near(*lat) {
        *lat = lat.round();
    }
    if near(*lng) {
        *lng = lng.round();
    }
}