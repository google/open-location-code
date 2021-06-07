use std::env::current_dir;
use std::fs::File;
use std::io::{BufRead, BufReader, Lines};

pub struct CSVReader {
    iter: Lines<BufReader<File>>,
}

impl CSVReader {
    pub fn new(csv_name: &str) -> CSVReader {
        // Assumes we're called from <open-location-code root>/rust
        let project_root = current_dir().unwrap();
        let olc_root = project_root.parent().unwrap();
        let csv_path = olc_root.join("test_data").join(csv_name);
        CSVReader {
            iter: BufReader::new(File::open(csv_path).unwrap()).lines(),
        }
    }
}

impl Iterator for CSVReader {
    type Item = String;

    fn next(&mut self) -> Option<String> {
        // Iterate lines in the CSV file, dropping empty & comment lines
        while let Some(Ok(s)) = self.iter.next() {
            if s.is_empty() || s.starts_with("#") {
                continue;
            }
            return Some(s);
        }
        None
    }
}
