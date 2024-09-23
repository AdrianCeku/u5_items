db = exports["u5_sqlite"]

local playerInventoryTableName = "player_inventory"
local containerInventoryTableName = "container_inventory"

function getUid(source)
    return "license:5879eeedc4a81dfd713978626df5e93371b361c3"
    -- return GetPlayerIdentifierByType(source, "license")
end

db:createTable(playerInventoryTableName,
    {
        {"uid", "STRING", "PRIMARY KEY NOT NULL"},
        {"stackable_items", "TEXT", "NOT NULL"},
        {"unique_items", "TEXT", "NOT NULL"}
    }
)

local function createPlayerEntry(source)
    db:insert(playerInventoryTableName, {uid = getUid(source), stackable_items = "{}", unique_items = "{}"})
end

local function getInventory(source)
    local result = db:select(playerInventoryTableName, {"stackable_items", "unique_items"}, {uid = getUid(source)})
    if not result then createPlayerEntry(source) return {stackables = {},  uniques= {}} end
    return {stackables = json.decode(result[1].stackable_items), uniques = json.decode(result[1].unique_items)}
end

local function setInventory(source, inventory)
    local stackable_items = json.encode(inventory.stackables)
    local unique_items = json.encode(inventory.uniques)

    db:update(playerInventoryTableName, {
        stackable_items = stackable_items,
        unique_items = unique_items
    }, {uid = getUid(source)})
end

local function doesMetaDataMatch(meta, metaDataToMatch)
    for key, value in pairs(matchMeta) do
        if not meta[key] then return false end
        if meta[key].value ~= value then return false end
    end

    return true
end

local function removeUniqueItemFromMetaData(source, metaDataToMatch)
    local inventory = getInventory(source)
    
    for i=1, #inventory.uniques do
        local item = inventory.uniques[i]
        local metaData = item.metaData

        if doesMetaDataMatch(metaData, metaDataToMatch) then
            table.remove(inventory.uniques, i)
            setInventory(source, inventory)
            return true
        end
    end

    return false
end

local function removeUniqueItemFromIndex(source, index)
    local inventory = getInventory(source)
    table.remove(inventory.uniques, index)
    setInventory(source, inventory)
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

    setInventory(source, inventory)
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

    setInventory(source, inventory)
end

local function giveUniqueItem(source, itemName, additionalMetaData)
    local item = ITEMS[itemName]
    if not item then return end

    local inventory = getInventory(source)
    local metaData = additionalMetaData or {}

    if item.metaData then
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
    end

    table.insert(inventory.uniques, {
            name = itemName,
            metaData = metaData
        } 
    )

    setInventory(source, inventory)
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

-- setInventory(source, inventory)

-- createPlayerEntry(1)
-- giveItem(1, "reusable_water_bottle", 1)
giveItem(1, "donut", 1)
-- removeItem(1, "water_bottle", 4)
-- print("Inventory:", 
--     json.encode(
--         getInventory(1)
--     )
-- )
-- db:delete(playerInventoryTableName, {uid = GetPlayerIdentifierByType(1, "license")})