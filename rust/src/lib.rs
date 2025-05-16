extern crate geo;

mod codearea;
mod consts;
mod interface;
mod private;

pub use codearea::CodeArea;
pub use interface::{decode, encode, encode_integers, is_full, is_short, is_valid, point_to_integers, recover_nearest, shorten};
