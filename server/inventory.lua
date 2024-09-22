db = exports["u5_sqlite"]

local playerInventoryTableName = "player_inventory"
local containerInventoryTableName = "container_inventory"

local emptyInventory = {
    stackables = {}, 
    uniques = {}
}

function getUid(source)
    return GetPlayerIdentifierByType(source, "license")
end

db:createTable(playerInventoryTableName,
    {
        {"uid", "STRING", "PRIMARY KEY NOT NULL"},
        {"items", "TEXT", "NOT NULL"}
    }
)

local function createPlayerEntry(source)
    db:insert(playerInventoryTableName, {uid = getUid(source), items = json.encode(emptyInventory)})
end

local function getInventory(source)
    local result = db:select(playerInventoryTableName, {"items"}, {uid = getUid(source)})
    if not result then createPlayerEntry(source) return emptyInventory end
    return json.decode(result[1].items)
end

local function matchTables(table1, table2)
    for k, v in pairs(table1) do
        if table2[k] ~= v then return false end
    end
    return true
end

local function removeUniqueItemFromMeta(source, metaDataToMatch)
    local inventory = getInventory(source)
    
    for i=1, #inventory.uniques do
        local item = inventory.uniques[i]
        local metaData = item.metaData

        if matchTables(metaData, metaDataToMatch) then
            table.remove(inventory.uniques, i)
            db:update(playerInventoryTableName, {items = json.encode(inventory)}, {uid = getUid(source)})
            return true
        end
    end

    return false
end

local function removeUniqueItemFromIndex(source, index)
    local inventory = getInventory(source)
    table.remove(inventory.uniques, index)
    db:update(playerInventoryTableName, {items = json.encode(inventory)}, {uid = getUid(source)})
end

local function removeStackableItem(source, itemName, amount)
    local inventory = getInventory(source)
    local currentAmount = inventory.stackables[itemName]

    if not currentAmount then return false end
    if currentAmount - amount < 0 then return false end

    inventory.stackables[itemName] = currentAmount - amount

    if inventory.stackables[itemName] == 0 then
        inventory.stackables[itemName] = nil
    end

    db:update(playerInventoryTableName, {items = json.encode(inventory)}, {uid = getUid(source)})
    return true
end

local function giveStackableItem(source, itemName, amount)
    local inventory = getInventory(source)
    local currentAmount = inventory.stackables[itemName]

    if currentAmount then
        inventory.stackables[itemName] = currentAmount + amount
    else
        inventory.stackables[itemName] = amount
    end

    db:update(playerInventoryTableName, {items = json.encode(inventory)}, {uid = getUid(source)})
end

local function giveUniqueItem(source, itemName, additionalMetaData)
    local item = ITEMS[itemName]
    if not item then return end

    local inventory = getInventory(source)
    local metaData = additionalMetaData or {}
        
    for name, data in pairs(item.metaData) do
        if metaData[name] then 
            print("Metadata\27[31m", name, "\27[0malready exists on\27[31m", itemName) 
            return	
        end

        metaData[name] = {
            showToPlayer = data.showToPlayer,
            value = data.onSpawn(),
        }
    end

    table.insert(inventory.unique, {
            name = itemName,
            metaData = metaData
        } 
    )

    db:update(playerInventoryTableName, {items = json.encode(inventory)}, {uid = getUid(source)})
end

local function giveItem(source, itemName, amount, additionalMetaData)
    local item = ITEMS[itemName]
    if not item then return end

    if item.stackable then
        giveStackableItem(source, itemName, amount)
    else
        for i=1, amount do
            giveUniqueItem(source, itemName, additionalMetaData)
        end
    end
end

-- db:update(playerInventoryTableName, {items = json.encode({
--     ["water_bottle"] = {
--         amount = 5,
--         metadata = {}
--     }
-- }
-- )}, {uid = GetPlayerIdentifierByType(1, "license")})


-- createPlayerEntry(1)
giveItem(1, "water_bottle", 1)
-- removeItem(1, "water_bottle", 4)
-- print("Inventory:", 
--     json.encode(
--         getInventory(1)
--     )
-- )
-- db:delete(playerInventoryTableName, {uid = GetPlayerIdentifierByType(1, "license")})