use geo::Point;

pub struct CodeArea {
    pub south: f64,
    pub west: f64,
    pub north: f64,
    pub east: f64,
    pub center: Point<f64>,
    pub code_length: usize,
}

impl CodeArea {
    pub fn new(south: f64, west: f64, north: f64, east: f64, code_length: usize) -> CodeArea {
        CodeArea {
            south,
            west,
            north,
            east,
            center: Point::new((west + east) / 2f64, (south + north) / 2f64),
            code_length,
        }
    }

    pub fn merge(self, other: CodeArea) -> CodeArea {
        CodeArea::new(
            self.south + other.south,
            self.west + other.west,
            self.north + other.north,
            self.east + other.east,
            self.code_length + other.code_length,
        )
    }
}
