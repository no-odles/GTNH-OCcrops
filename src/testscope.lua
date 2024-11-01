local db = require("testdb")

local sss = db.getSeedStoreSlot()

local function psss()
    print(db.getSeedStoreSlot())
end

db.incSeedStoreSlot()
return {sss=sss, psss = psss}
