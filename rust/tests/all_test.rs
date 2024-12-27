extern crate geo;
extern crate open_location_code;
extern crate rand;

use rand::Rng;
use std::time::Instant;
use std::vec::Vec;

use open_location_code::{decode, encode};
use open_location_code::{is_full, is_short, is_valid};
use open_location_code::{recover_nearest, shorten};

use geo::Point;

mod csv_reader;

use csv_reader::CSVReader;

/// CSVReader is written to swallow errors; as such, we might "pass" tests because we didn't
/// actually run any!  Thus, we use 'tested' below to count # lines read and hence to assert that
/// > 0 tests were executed.
///
/// We could probably take it a little further, and assert that tested was >= # tests in the file
/// (allowing tests to be added, but assuming # tests will never be reduced).
#[test]
fn is_valid_test() {
    let mut tested = 0;
    for line in CSVReader::new("validityTests.csv") {
        let cols: Vec<&str> = line.split(',').collect();
        let code = cols[0];
        let _valid = cols[1] == "true";
        let _short = cols[2] == "true";
        let _full = cols[3] == "true";

        assert_eq!(is_valid(code), _valid, "valid for code: {}", code);
        assert_eq!(is_short(code), _short, "short for code: {}", code);
        assert_eq!(is_full(code), _full, "full for code: {}", code);

        tested += 1;
    }
    assert!(tested > 0);
}

#[test]
fn decode_test() {
    let mut tested = 0;
    for line in CSVReader::new("decoding.csv") {
        let cols: Vec<&str> = line.split(',').collect();
        let code = cols[0];
        let len = cols[1].parse::<usize>().unwrap();
        let latlo = cols[2].parse::<f64>().unwrap();
        let lnglo = cols[3].parse::<f64>().unwrap();
        let lathi = cols[4].parse::<f64>().unwrap();
        let lnghi = cols[5].parse::<f64>().unwrap();

        let codearea = decode(code).unwrap();
        assert_eq!(codearea.code_length, len, "code length");
        assert!((latlo - codearea.south).abs() < 1e-10f64);
        assert!((lathi - codearea.north).abs() < 1e-10f64);
        assert!((lnglo - codearea.west).abs() < 1e-10f64);
        assert!((lnghi - codearea.east).abs() < 1e-10f64);

        tested += 1;
    }
    assert!(tested > 0);
}

#[test]
fn encode_test() {
    let mut tested = 0;
    for line in CSVReader::new("encoding.csv") {
        if line.chars().count() == 0 {
            continue;
        }
        let cols: Vec<&str> = line.split(',').collect();
        let lat = cols[0].parse::<f64>().unwrap();
        let lng = cols[1].parse::<f64>().unwrap();
        let len = cols[2].parse::<usize>().unwrap();
        let code = cols[3];

        assert_eq!(
            encode(Point::new(lng, lat), len),
            code,
            "encoding lat={},lng={},len={}",
            lat,
            lng,
            len
        );

        tested += 1;
    }
    assert!(tested > 0);
}

#[test]
fn shorten_recovery_test() {
    let mut tested = 0;
    for line in CSVReader::new("shortCodeTests.csv") {
        let cols: Vec<&str> = line.split(',').collect();
        let full_code = cols[0];
        let lat = cols[1].parse::<f64>().unwrap();
        let lng = cols[2].parse::<f64>().unwrap();
        let short_code = cols[3];
        let test_type = cols[4];

        if test_type == "B" || test_type == "S" {
            assert_eq!(
                shorten(full_code, Point::new(lng, lat)).unwrap(),
                short_code,
                "shorten"
            );
        }
        if test_type == "B" || test_type == "R" {
            assert_eq!(
                recover_nearest(short_code, Point::new(lng, lat)),
                Ok(full_code.to_string()),
                "recover"
            );
        }

        tested += 1;
    }
    assert!(tested > 0);
}

#[test]
fn benchmark_test() {
    struct BenchmarkData {
        lat: f64,
        lng: f64,
        len: usize,
    }
    let mut rng = rand::thread_rng();
    // Create the benchmark data - coordinates and lengths for encoding, codes for decoding.
    let loops = 100000;
    let mut bd: Vec<BenchmarkData> = Vec::new();
    for _i in 0..loops {
        let lat = rng.gen_range(-90.0..90.0);
        let lng = rng.gen_range(-180.0..180.0);
        let mut len = rng.gen_range(2..15);
        // Make sure the length is even if it's less than 10.
        if len < 10 && len % 2 == 1 {
            len += 1;
        }
        let b = BenchmarkData {
            lat: lat,
            lng: lng,
            len: len,
        };
        bd.push(b);
    }

    // Do the encode benchmark.
    // Get the current time, loop through the benchmark data, print the time.
    let mut codes: Vec<String> = Vec::new();
    let mut now = Instant::now();
    for b in &bd {
        codes.push(encode(Point::new(b.lng, b.lat), b.len));
    }
    let enc_duration = now.elapsed().as_secs() * 1000000 + now.elapsed().subsec_micros() as u64;

    // Do the encode benchmark.
    // Get the current time, loop through the benchmark data, print the time.
    now = Instant::now();
    for c in codes {
        let _c = decode(&c);
    }
    let dec_duration = now.elapsed().as_secs() * 1000000 + now.elapsed().subsec_micros() as u64;
    // Output.
    println!(
        "Encoding benchmark: {} loops, total time {} usec, {} usec per encode",
        loops,
        enc_duration,
        enc_duration as f64 / loops as f64
    );
    println!(
        "Decoding benchmark: {} loops, total time {} usec, {} usec per decode",
        loops,
        dec_duration,
        dec_duration as f64 / loops as f64
    );
}
