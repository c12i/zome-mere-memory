mod memory_block_handlers;
mod memory_handlers;

pub use mere_memory::*;

use hdk::prelude::*;

#[hdk_extern]
fn init(_: ()) -> ExternResult<InitCallbackResult> {
    Ok(InitCallbackResult::Pass)
}

#[hdk_extern]
pub fn make_hash_path(hash: String) -> ExternResult<Path> {
    let path = Path::from(hash);

    Ok(path)
}
