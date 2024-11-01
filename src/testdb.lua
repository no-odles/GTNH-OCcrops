local seed_store_slot=1

local function incSeedStoreSlot()
    seed_store_slot = seed_store_slot + 1
    return seed_store_slot
end

local function getSeedStoreSlot()
    return seed_store_slot
end

return {
    seed_store_slot=seed_store_slot, 
    incSeedStoreSlot=incSeedStoreSlot, 
    getSeedStoreSlot=getSeedStoreSlot
}