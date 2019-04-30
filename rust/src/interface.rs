use geo::Point;

use codearea::CodeArea;

use consts::{
    SEPARATOR, SEPARATOR_POSITION, PADDING_CHAR, PADDING_CHAR_STR, CODE_ALPHABET, ENCODING_BASE,
    LATITUDE_MAX, LONGITUDE_MAX, PAIR_CODE_LENGTH, MAX_CODE_LENGTH, PAIR_RESOLUTIONS, GRID_COLUMNS, GRID_ROWS,
    MIN_TRIMMABLE_CODE_LEN,
};

use private::{
    code_value, normalize_longitude, clip_latitude, compute_latitude_precision, prefix_by_reference,
    narrow_region,
};

/// Determines if a code is a valid Open Location Code.
pub fn is_valid(_code: &str) -> bool {
    let mut code: String = _code.to_string();
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
    if padstart.is_some() {
        if spos < SEPARATOR_POSITION {
            // Short codes cannot have padding
            return false;
        }
        let ppos = padstart.unwrap();
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
        let padding: String = code.drain(ppos..eppos+1).collect();
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
pub fn is_short(_code: &str) -> bool {
    is_valid(_code) &&
        _code.find(SEPARATOR).unwrap() < SEPARATOR_POSITION
}

/// Determines if a code is a valid full Open Location Code.
///
/// Not all possible combinations of Open Location Code characters decode to
/// valid latitude and longitude values. This checks that a code is valid
/// and also that the latitude and longitude values are legal. If the prefix
/// character is present, it must be the first character. If the separator
/// character is present, it must be after four characters.
pub fn is_full(_code: &str) -> bool {
    is_valid(_code) && !is_short(_code)
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
    let mut lng = normalize_longitude(pt.lng());

    let mut trimmed_code_length = code_length;
    if trimmed_code_length > MAX_CODE_LENGTH {
        trimmed_code_length = MAX_CODE_LENGTH;
    }

    // Latitude 90 needs to be adjusted to be just less, so the returned code
    // can also be decoded.
    if lat > LATITUDE_MAX || (LATITUDE_MAX - lat) < 1e-10f64 {
        lat -= compute_latitude_precision(trimmed_code_length);
    }

    lat += LATITUDE_MAX;
    lng += LONGITUDE_MAX;

    let mut code = String::with_capacity(trimmed_code_length + 1);
    let mut digit = 0;
    while digit < trimmed_code_length {
        narrow_region(digit, &mut lat, &mut lng);

        let lat_digit = lat as usize;
        let lng_digit = lng as usize;
        if digit < PAIR_CODE_LENGTH {
            code.push(CODE_ALPHABET[lat_digit]);
            code.push(CODE_ALPHABET[lng_digit]);
            digit += 2;
        } else {
            code.push(CODE_ALPHABET[4 * lat_digit + lng_digit]);
            digit += 1;
        }
        lat -= lat_digit as f64;
        lng -= lng_digit as f64;
        if digit == SEPARATOR_POSITION {
            code.push(SEPARATOR);
        }
    }
    if digit < SEPARATOR_POSITION {
        code.push_str(
            PADDING_CHAR_STR.repeat(SEPARATOR_POSITION - digit).as_str()
        );
        code.push(SEPARATOR);
    }
    code
}

/// Decodes an Open Location Code into the location coordinates.
///
/// Returns a CodeArea object that includes the coordinates of the bounding
/// box - the lower left, center and upper right.
pub fn decode(_code: &str) -> Result<CodeArea, String> {
    if !is_full(_code) {
        return Err(format!("Code must be a valid full code: {}", _code));
    }
    let mut code = _code.to_string()
        .replace(SEPARATOR, "")
        .replace(PADDING_CHAR_STR, "")
        .to_uppercase();
    if code.len() > MAX_CODE_LENGTH {
        code = code.chars().take(MAX_CODE_LENGTH).collect();
    }

    let mut lat = -LATITUDE_MAX;
    let mut lng = -LONGITUDE_MAX;
    let mut lat_res = ENCODING_BASE * ENCODING_BASE;
    let mut lng_res = ENCODING_BASE * ENCODING_BASE;

    for (idx, chr) in code.chars().enumerate() {
        if idx < PAIR_CODE_LENGTH {
            if idx % 2 == 0 {
                lat_res /= ENCODING_BASE;
                lat += lat_res * code_value(chr) as f64;
            } else {
                lng_res /= ENCODING_BASE;
                lng += lng_res * code_value(chr) as f64;
            }
        } else if idx < MAX_CODE_LENGTH {
            lat_res /= GRID_ROWS;
            lng_res /= GRID_COLUMNS;
            lat += lat_res * (code_value(chr) as f64 / GRID_COLUMNS).trunc();

            lng += lng_res * (code_value(chr) as f64 % GRID_COLUMNS);
        }
    }
    Ok(CodeArea::new(lat, lng, lat + lat_res, lng + lng_res, code.len()))
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
pub fn shorten(_code: &str, ref_pt: Point<f64>) -> Result<String, String> {
    if !is_full(_code) {
        return Ok(_code.to_string());
    }
    if _code.find(PADDING_CHAR).is_some() {
        return Err("Cannot shorten padded codes".to_owned());
    }

    let codearea: CodeArea = decode(_code).unwrap();
    if codearea.code_length < MIN_TRIMMABLE_CODE_LEN {
        return Err(format!("Code length must be at least {}", MIN_TRIMMABLE_CODE_LEN));
    }

    // How close are the latitude and longitude to the code center.
    let range = (codearea.center.lat() - clip_latitude(ref_pt.lat())).abs().max(
        (codearea.center.lng() - normalize_longitude(ref_pt.lng())).abs()
    );

    for i in 0..PAIR_RESOLUTIONS.len() - 2 {
        // Check if we're close enough to shorten. The range must be less than 1/2
        // the resolution to shorten at all, and we want to allow some safety, so
        // use 0.3 instead of 0.5 as a multiplier.
        let idx = PAIR_RESOLUTIONS.len() - 2 - i;
        if range < (PAIR_RESOLUTIONS[idx] * 0.3f64) {
            let mut code = _code.to_string();
            code.drain(..((idx + 1) * 2));
            return Ok(code);
        }
    }
    Ok(_code.to_string())
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
pub fn recover_nearest(_code: &str, ref_pt: Point<f64>) -> Result<String, String> {
    if !is_short(_code) {
        if is_full(_code) {
            return Ok(_code.to_string().to_uppercase());
        } else {
            return Err(format!("Passed short code is not valid: {}", _code));
        }
    }

    let prefix_len = SEPARATOR_POSITION - _code.find(SEPARATOR).unwrap();
    let mut code = prefix_by_reference(ref_pt, prefix_len);
    code.push_str(_code);

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
    Ok(encode(Point::new(longitude, latitude), code_area.code_length))
}

