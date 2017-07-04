extern crate geo;

mod consts;
mod private;

mod codearea;
pub use codearea::CodeArea;

mod interface;
pub use interface::{is_valid, is_short, is_full, encode, decode, shorten, recover_nearest};

