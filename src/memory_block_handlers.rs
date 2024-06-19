use crate::{MemoryBlockEntry, ToInput};

use hdk::prelude::*;

#[hdk_extern]
pub fn create_memory_block_entry(block: MemoryBlockEntry) -> ExternResult<EntryHash> {
    debug!(
        "Creating 'MemoryBlockEntry' ({}/{}): {}",
        block.sequence.position,
        block.sequence.length,
        block.bytes.len()
    );

    create_entry(block.to_input())?;

    Ok(hash_entry(&block)?)
}

#[hdk_extern]
pub fn get_memory_block_entry(addr: EntryHash) -> ExternResult<MemoryBlockEntry> {
    debug!("Get 'MemoryBlockEntry': {}", addr);
    let record = get(addr.clone(), GetOptions::network())?.ok_or(wasm_error!(
        WasmErrorInner::Guest(format!("Entry not found for address: {}", addr))
    ))?;
    let block = MemoryBlockEntry::try_from(&record)?;

    Ok(block)
}
