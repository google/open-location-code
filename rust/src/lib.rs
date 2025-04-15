extern crate geo;

mod codearea;
mod consts;
mod interface;
mod private;

pub use codearea::CodeArea;
pub use interface::{decode, encode, is_full, is_short, is_valid, recover_nearest, shorten};
