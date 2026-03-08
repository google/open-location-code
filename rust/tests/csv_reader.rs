use std::env::current_dir;
use std::fs::File;
use std::io::{BufRead, BufReader, Lines, Error};
use std::io::ErrorKind::InvalidInput;
use std::path::PathBuf;

pub struct CSVReader {
    iter: Lines<BufReader<File>>,
}

impl CSVReader {
    pub fn new(csv_name: &str) -> Result<CSVReader, Error> {
        // Assumes we're called from <open-location-code root>/rust
        let project_root = current_dir()?;

        let olc_root: PathBuf = match project_root.file_name().and_then(|n| n.to_str()) {
            Some("rust") => project_root
                .parent()
                .map(|p| p.to_path_buf())
                .ok_or_else(|| Error::new(InvalidInput, "Could not find project root parent")),
            Some("_main") => Ok(project_root.clone()),
            _ => {
                return Err(Error::new(InvalidInput, format!(
                    "Expected current dir to end with 'rust' or '_main', got {:?}",
                    project_root
                )));
            }
        }?;
        let csv_path = olc_root.join("test_data").join(csv_name);

        let file = File::open(&csv_path).map_err(|e| {
            Error::new(e.kind(), format!(
                "Failed to open CSV file at {:?}: {} (Current dir: {:?})",
                csv_path, e, project_root
            ))
        })?;

        Ok(CSVReader {
            iter: BufReader::new(file).lines(),
        })
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
