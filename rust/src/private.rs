use consts::{
    CODE_ALPHABET, ENCODING_BASE, GRID_ROWS, LATITUDE_MAX, LONGITUDE_MAX, PAIR_CODE_LENGTH,
};

use interface::encode;

use geo::Point;

pub fn code_value(chr: char) -> usize {
    // We assume this function is only called by other functions that have
    // already ensured that the characters in the passed-in code are all valid
    // and have all been "treated" (upper-cased, padding and '+' stripped)
    CODE_ALPHABET.iter().position(|&x| x == chr).unwrap()
}

pub fn normalize_longitude(value: f64) -> f64 {
    let mut result: f64 = value;
    while result >= LONGITUDE_MAX {
        result -= LONGITUDE_MAX * 2f64;
    }
    while result < -LONGITUDE_MAX {
        result += LONGITUDE_MAX * 2f64;
    }
    result
}

pub fn clip_latitude(latitude_degrees: f64) -> f64 {
    latitude_degrees.min(LATITUDE_MAX).max(-LATITUDE_MAX)
}

pub fn compute_latitude_precision(code_length: usize) -> f64 {
    if code_length <= PAIR_CODE_LENGTH {
        return (ENCODING_BASE as f64).powf((code_length as f64 / -2f64 + 2f64).floor());
    }
    (ENCODING_BASE as f64).powf(-3f64)
        / GRID_ROWS.pow((code_length - PAIR_CODE_LENGTH) as u32) as f64
}

pub fn prefix_by_reference(pt: Point<f64>, code_length: usize) -> String {
    let precision = compute_latitude_precision(code_length);
    let mut code = encode(
        Point::new(
            (pt.lng() / precision).floor() * precision,
            (pt.lat() / precision).floor() * precision,
        ),
        PAIR_CODE_LENGTH,
    );
    code.drain(code_length..);
    code
}
