use consts::{
    CODE_ALPHABET, ENCODING_BASE, LATITUDE_MAX, LONGITUDE_MAX, PAIR_CODE_LENGTH, GRID_ROWS,
    GRID_COLUMNS, NARROW_REGION_PRECISION,
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
    while result < -LONGITUDE_MAX{
        result += LONGITUDE_MAX * 2f64;
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
    ENCODING_BASE.powi(-3i32) / GRID_ROWS.powf(code_length as f64 - PAIR_CODE_LENGTH as f64)
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

// Apply "gravity" towards closest integer value, if current value is closer that given threshold.
// This is a way to compensate aggregated error caused by floating point precision restriction.
fn near(value: f64, error: f64) -> f64 {
    let target = (value + error).trunc();
    if value.trunc() != target {
        target
    } else {
        value
    }
}

pub fn narrow_region(digit: usize, lat: &mut f64, lng: &mut f64) {
    if digit == 0 {
        *lat /= ENCODING_BASE;
        *lng /= ENCODING_BASE;
    } else if digit < PAIR_CODE_LENGTH {
        *lat *= ENCODING_BASE;
        *lng *= ENCODING_BASE;
    } else {
        *lat *= GRID_ROWS;
        *lng *= GRID_COLUMNS
    }
    *lat = near(*lat, NARROW_REGION_PRECISION);
    *lng = near(*lng, NARROW_REGION_PRECISION);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn near_applied() {
        let value = 3.0f64 - NARROW_REGION_PRECISION * 2.;
        assert_eq!(near(value, NARROW_REGION_PRECISION), value);
    }

    #[test]
    fn near_not_applied() {
        let value = 3.0f64 - NARROW_REGION_PRECISION;
        assert_eq!(near(value, NARROW_REGION_PRECISION), 3.0f64);
    }
}
