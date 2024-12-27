use geo::Point;
use std::cmp;

use codearea::CodeArea;

use consts::{
    CODE_ALPHABET, ENCODING_BASE, GRID_CODE_LENGTH, GRID_COLUMNS, GRID_ROWS, LATITUDE_MAX,
    LAT_INTEGER_MULTIPLIER, LNG_INTEGER_MULTIPLIER, LONGITUDE_MAX, MAX_CODE_LENGTH,
    MIN_CODE_LENGTH, MIN_TRIMMABLE_CODE_LEN, PADDING_CHAR, PADDING_CHAR_STR, PAIR_CODE_LENGTH,
    PAIR_RESOLUTIONS, SEPARATOR, SEPARATOR_POSITION,
};

use private::{
    clip_latitude, code_value, compute_latitude_precision, normalize_longitude, prefix_by_reference,
};

/// Determines if a code is a valid Open Location Code.
pub fn is_valid(code: &str) -> bool {
    let mut code: String = code.to_string();
    if code.len() < 3 {
        // A code must have at-least a separator character + 1 lat/lng pair
        return false;
    }

    // Validate separator character
    if code.find(SEPARATOR).is_none() {
        // The code MUST contain a separator character
        return false;
    }
    if code.find(SEPARATOR) != code.rfind(SEPARATOR) {
        // .. And only one separator character
        return false;
    }
    let spos = code.find(SEPARATOR).unwrap();
    if spos % 2 == 1 || spos > SEPARATOR_POSITION {
        // The separator must be in a valid location
        return false;
    }
    if code.len() - spos - 1 == 1 {
        // There must be > 1 character after the separator
        return false;
    }

    // Validate padding
    let padstart = code.find(PADDING_CHAR);
    if let Some(ppos) = padstart {
        if spos < SEPARATOR_POSITION {
            // Short codes cannot have padding
            return false;
        }
        if ppos == 0 || ppos % 2 == 1 {
            // Padding must be "within" the string, starting at an even position
            return false;
        }
        if code.len() > spos + 1 {
            // If there is padding, the code must end with the separator char
            return false;
        }
        let eppos = code.rfind(PADDING_CHAR).unwrap();
        if eppos - ppos % 2 == 1 {
            // Must have even number of padding chars
            return false;
        }
        // Extract the padding from the code (mutates code)
        let padding: String = code.drain(ppos..eppos + 1).collect();
        if padding.chars().any(|c| c != PADDING_CHAR) {
            // Padding must be one, contiguous block of padding chars
            return false;
        }
    }

    // Validate all characters are permissible
    code.chars()
        .map(|c| c.to_ascii_uppercase())
        .all(|c| c == SEPARATOR || CODE_ALPHABET.contains(&c))
}

/// Determines if a code is a valid short code.
///
/// A short Open Location Code is a sequence created by removing four or more
/// digits from an Open Location Code. It must include a separator character.
pub fn is_short(code: &str) -> bool {
    is_valid(code) && code.find(SEPARATOR).unwrap() < SEPARATOR_POSITION
}

/// Determines if a code is a valid full Open Location Code.
///
/// Not all possible combinations of Open Location Code characters decode to
/// valid latitude and longitude values. This checks that a code is valid
/// and also that the latitude and longitude values are legal. If the prefix
/// character is present, it must be the first character. If the separator
/// character is present, it must be after four characters.
pub fn is_full(code: &str) -> bool {
    is_valid(code) && !is_short(code)
}

/// Encode a location into an Open Location Code.
///
/// Produces a code of the specified length, or the default length if no
/// length is provided.
/// The length determines the accuracy of the code. The default length is
/// 10 characters, returning a code of approximately 13.5x13.5 meters. Longer
/// codes represent smaller areas, but lengths > 14 are sub-centimetre and so
/// 11 or 12 are probably the limit of useful codes.
pub fn encode(pt: Point<f64>, code_length: usize) -> String {
    let mut lat = clip_latitude(pt.lat());
    let lng = normalize_longitude(pt.lng());

    let trimmed_code_length = cmp::min(cmp::max(code_length, MIN_CODE_LENGTH), MAX_CODE_LENGTH);

    // Latitude 90 needs to be adjusted to be just less, so the returned code
    // can also be decoded.
    if lat > LATITUDE_MAX || (LATITUDE_MAX - lat) < 1e-10f64 {
        lat -= compute_latitude_precision(trimmed_code_length);
    }

    // Convert to integers.
    let mut lat_val =
        (((lat + LATITUDE_MAX) * LAT_INTEGER_MULTIPLIER as f64 * 1e6).round() / 1e6f64) as i64;
    let mut lng_val =
        (((lng + LONGITUDE_MAX) * LNG_INTEGER_MULTIPLIER as f64 * 1e6).round() / 1e6f64) as i64;

    // Compute the code digits. This largely ignores the requested length - it
    // generates either a 10 digit code, or a 15 digit code, and then truncates
    // it to the requested length.

    // Build up the code digits in reverse order.
    let mut rev_code = String::with_capacity(trimmed_code_length + 1);

    // First do the grid digits.
    if code_length > PAIR_CODE_LENGTH {
        for _i in 0..GRID_CODE_LENGTH {
            let lat_digit = lat_val % GRID_ROWS as i64;
            let lng_digit = lng_val % GRID_COLUMNS as i64;
            let ndx = (lat_digit * GRID_COLUMNS as i64 + lng_digit) as usize;
            rev_code.push(CODE_ALPHABET[ndx]);
            lat_val /= GRID_ROWS as i64;
            lng_val /= GRID_COLUMNS as i64;
        }
    } else {
        // Adjust latitude and longitude values to skip the grid digits.
        lat_val /= GRID_ROWS.pow(GRID_CODE_LENGTH as u32) as i64;
        lng_val /= GRID_COLUMNS.pow(GRID_CODE_LENGTH as u32) as i64;
    }
    // Compute the pair section of the code.
    for i in 0..PAIR_CODE_LENGTH / 2 {
        rev_code.push(CODE_ALPHABET[(lng_val % ENCODING_BASE as i64) as usize]);
        lng_val /= ENCODING_BASE as i64;
        rev_code.push(CODE_ALPHABET[(lat_val % ENCODING_BASE as i64) as usize]);
        lat_val /= ENCODING_BASE as i64;
        // If we are at the separator position, add the separator.
        if i == 0 {
            rev_code.push(SEPARATOR);
        }
    }
    let mut code: String;
    // If we need to pad the code, replace some of the digits.
    if code_length < SEPARATOR_POSITION {
        code = rev_code.chars().rev().take(code_length).collect();
        code.push_str(
            PADDING_CHAR_STR
                .repeat(SEPARATOR_POSITION - code_length)
                .as_str(),
        );
        code.push(SEPARATOR);
    } else {
        code = rev_code.chars().rev().take(code_length + 1).collect();
    }

    code
}

/// Decodes an Open Location Code into the location coordinates.
///
/// Returns a CodeArea object that includes the coordinates of the bounding
/// box - the lower left, center and upper right.
pub fn decode(code: &str) -> Result<CodeArea, String> {
    if !is_full(code) {
        return Err(format!("Code must be a valid full code: {}", code));
    }
    let mut code = code
        .to_string()
        .replace(SEPARATOR, "")
        .replace(PADDING_CHAR_STR, "")
        .to_uppercase();
    if code.len() > MAX_CODE_LENGTH {
        code = code.chars().take(MAX_CODE_LENGTH).collect();
    }

    // Work out the values as integers and convert to floating point at the end.
    let mut lat: i64 = -90 * LAT_INTEGER_MULTIPLIER;
    let mut lng: i64 = -180 * LNG_INTEGER_MULTIPLIER;
    let mut lat_place_val: i64 = LAT_INTEGER_MULTIPLIER * ENCODING_BASE.pow(2) as i64;
    let mut lng_place_val: i64 = LNG_INTEGER_MULTIPLIER * ENCODING_BASE.pow(2) as i64;

    for (idx, chr) in code.chars().enumerate() {
        if idx < PAIR_CODE_LENGTH {
            if idx % 2 == 0 {
                lat_place_val /= ENCODING_BASE as i64;
                lat += lat_place_val * code_value(chr) as i64;
            } else {
                lng_place_val /= ENCODING_BASE as i64;
                lng += lng_place_val * code_value(chr) as i64;
            }
        } else {
            lat_place_val /= GRID_ROWS as i64;
            lng_place_val /= GRID_COLUMNS as i64;
            lat += lat_place_val * (code_value(chr) / GRID_COLUMNS) as i64;
            lng += lng_place_val * (code_value(chr) % GRID_COLUMNS) as i64;
        }
    }
    // Convert to floating point values.
    let lat_lo: f64 = lat as f64 / LAT_INTEGER_MULTIPLIER as f64;
    let lng_lo: f64 = lng as f64 / LNG_INTEGER_MULTIPLIER as f64;
    let lat_hi: f64 =
        (lat + lat_place_val) as f64 / (ENCODING_BASE.pow(3) * GRID_ROWS.pow(5)) as f64;
    let lng_hi: f64 =
        (lng + lng_place_val) as f64 / (ENCODING_BASE.pow(3) * GRID_COLUMNS.pow(5)) as f64;
    Ok(CodeArea::new(lat_lo, lng_lo, lat_hi, lng_hi, code.len()))
}

/// Remove characters from the start of an OLC code.
///
/// This uses a reference location to determine how many initial characters
/// can be removed from the OLC code. The number of characters that can be
/// removed depends on the distance between the code center and the reference
/// location.
/// The minimum number of characters that will be removed is four. If more
/// than four characters can be removed, the additional characters will be
/// replaced with the padding character. At most eight characters will be
/// removed.
/// The reference location must be within 50% of the maximum range. This
/// ensures that the shortened code will be able to be recovered using
/// slightly different locations.
///
/// It returns either the original code, if the reference location was not
/// close enough, or the .
pub fn shorten(code: &str, ref_pt: Point<f64>) -> Result<String, String> {
    if !is_full(code) {
        return Ok(code.to_string());
    }
    if code.find(PADDING_CHAR).is_some() {
        return Err("Cannot shorten padded codes".to_owned());
    }

    let codearea: CodeArea = decode(code).unwrap();
    if codearea.code_length < MIN_TRIMMABLE_CODE_LEN {
        return Err(format!(
            "Code length must be at least {}",
            MIN_TRIMMABLE_CODE_LEN
        ));
    }

    // How close are the latitude and longitude to the code center.
    let range = (codearea.center.lat() - clip_latitude(ref_pt.lat()))
        .abs()
        .max((codearea.center.lng() - normalize_longitude(ref_pt.lng())).abs());

    for i in 0..PAIR_RESOLUTIONS.len() - 2 {
        // Check if we're close enough to shorten. The range must be less than 1/2
        // the resolution to shorten at all, and we want to allow some safety, so
        // use 0.3 instead of 0.5 as a multiplier.
        let idx = PAIR_RESOLUTIONS.len() - 2 - i;
        if range < (PAIR_RESOLUTIONS[idx] * 0.3f64) {
            let mut code = code.to_string();
            code.drain(..((idx + 1) * 2));
            return Ok(code);
        }
    }
    Ok(code.to_string())
}

/// Recover the nearest matching code to a specified location.
///
/// Given a short Open Location Code of between four and seven characters,
/// this recovers the nearest matching full code to the specified location.
/// The number of characters that will be prepended to the short code, depends
/// on the length of the short code and whether it starts with the separator.
/// If it starts with the separator, four characters will be prepended. If it
/// does not, the characters that will be prepended to the short code, where S
/// is the supplied short code and R are the computed characters, are as
/// follows:
///
/// * SSSS    -> RRRR.RRSSSS
/// * SSSSS   -> RRRR.RRSSSSS
/// * SSSSSS  -> RRRR.SSSSSS
/// * SSSSSSS -> RRRR.SSSSSSS
///
/// Note that short codes with an odd number of characters will have their
/// last character decoded using the grid refinement algorithm.
///
/// It returns the nearest full Open Location Code to the reference location
/// that matches the [shortCode]. Note that the returned code may not have the
/// same computed characters as the reference location (provided by
/// [referenceLatitude] and [referenceLongitude]). This is because it returns
/// the nearest match, not necessarily the match within the same cell. If the
/// passed code was not a valid short code, but was a valid full code, it is
/// returned unchanged.
pub fn recover_nearest(code: &str, ref_pt: Point<f64>) -> Result<String, String> {
    if !is_short(code) {
        if is_full(code) {
            return Ok(code.to_string().to_uppercase());
        } else {
            return Err(format!("Passed short code is not valid: {}", code));
        }
    }

    let prefix_len = SEPARATOR_POSITION - code.find(SEPARATOR).unwrap();
    let code = prefix_by_reference(ref_pt, prefix_len) + code;

    let code_area = decode(code.as_str()).unwrap();

    let resolution = compute_latitude_precision(prefix_len);
    let half_res = resolution / 2f64;

    let mut latitude = code_area.center.lat();
    let mut longitude = code_area.center.lng();

    let ref_lat = clip_latitude(ref_pt.lat());
    let ref_lng = normalize_longitude(ref_pt.lng());
    if ref_lat + half_res < latitude && latitude - resolution >= -LATITUDE_MAX {
        latitude -= resolution;
    } else if ref_lat - half_res > latitude && latitude + resolution <= LATITUDE_MAX {
        latitude += resolution;
    }
    if ref_lng + half_res < longitude {
        longitude -= resolution;
    } else if ref_lng - half_res > longitude {
        longitude += resolution;
    }
    Ok(encode(
        Point::new(longitude, latitude),
        code_area.code_length,
    ))
}
