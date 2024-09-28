local playerInventoryTableName = "player_inventory"

db:createTable(playerInventoryTableName,
    {
        {"player_id", "STRING", "PRIMARY KEY NOT NULL"},
        {"stackable_items", "TEXT", "NOT NULL"},
        {"unique_items", "TEXT", "NOT NULL"}
    }
)

--+--+--+--+--+--+--+ create / delete +--+--+--+--+--+--+--+

local function getPlayerId(source)
    return "license:5879eeedc4a81dfd713978626df5e93371b361c3"
    -- return GetPlayerIdentifierByType(source, "license")
end

local function createPlayerEntry(source)
    db:insert(playerInventoryTableName, {
        player_id = getPlayerId(source), 
        emptyInventoryEntry}
    )
end

--+--+--+--+--+--+--+ get inventory +--+--+--+--+--+--+--+

local function getPlayerFromDb(source, columns)
    local result = db:select(playerInventoryTableName, columns, {player_id = getPlayerId(source)})
    if not result then createPlayerEntry(source) return emptyInventoryEntry end
    return result[1]
end

function getPlayerUniques(source)
    local result = getPlayerFromDb(source, {"unique_items"})
    return json.decode(result.unique_items)
end

function getPlayerStackables(source)
    local result = getPlayerFromDb(source, {"stackable_items"})
    return json.decode(result.stackable_items)
end

function getPlayerInventory(source)
    local result = getPlayerFromDb(source, {"stackable_items", "unique_items"})
    return {stackables = json.decode(result.stackable_items), uniques = json.decode(result.unique_items)}
end

--+--+--+--+--+--+--+ set inventory +--+--+--+--+--+--+--+

function setPlayerUniques(source, uniques)
    db:update(playerInventoryTableName, {unique_items = json.encode(uniques)}, {player_id = getPlayerId(source)})
end

function setPlayerStackables(source, stackables)
    db:update(playerInventoryTableName, {stackable_items = json.encode(stackables)}, {player_id = getPlayerId(source)})
end

function setPlayerInventory(source, inventory)
    db:update(playerInventoryTableName, {
        stackable_items = json.encode(inventory.stackables),
        unique_items = json.encode(inventory.uniques)
    }, {player_id = getPlayerId(source)})
end

--+--+--+--+--+--+--+ give item +--+--+--+--+--+--+--+

function givePlayerStackableItem(source, itemName, amount)
    local inventory = getPlayerInventory(source)
    if (not canPlayerCarryItems(inventory.stackables, inventory.uniques, itemName, amount)
        or 
        not canPlayerFitItems(inventory.stackables, inventory.uniques, itemName, amount)
    ) then return false end

    local stackables = addToStackables(inventory.stackables, itemName, amount)
    setPlayerStackables(source, stackables)
    return true
end

function givePlayerUniqueItem(source, itemName, amount, additionalMetaData)
    local inventory = getPlayerInventory(source)
    if (not canPlayerCarryItems(inventory.stackables, inventory.uniques, itemName, amount)
        or 
        not canPlayerFitItems(inventory.stackables, inventory.uniques, itemName, amount)
    ) then return false end

    for i=1, amount do
        uniques = addToUniques(source, inventory.uniques, itemName, additionalMetaData)
    end
    setPlayerUniques(source, uniques)
    return true
end

function givePlayerItem(source, itemName, amount, additionalMetaData)
    local item = ITEMS[itemName]
    if not item then return end

    if item.stackable then return givePlayerStackableItem(source, itemName, amount) end
    return givePlayerUniqueItem(source, itemName, amount, additionalMetaData)
end

--+--+--+--+--+--+--+ remove item +--+--+--+--+--+--+--+

function removePlayerStackableItem(source, itemName, amount)
    local stackables = getPlayerStackables(source)
    if not doStackablesIncludeItem(stackables, itemName, amount) then return false end
    stackables = removeFromStackables(stackables, itemName, amount)
    setPlayerStackables(source, stackables)
    return true
end

function removePlayerUniqueItem(source, itemName, amount, metaData)
    local uniques = getPlayerUniques(source)

    for i=1, amount do 
        local hasItem, index = doUniquesIncludeItem(uniques, itemName, metaData)
        if not hasItem then return false end
        table.remove(uniques, index)
    end

    setPlayerUniques(source, uniques)
    return true
end

function removePlayerItem(source, itemName, amount, metaData)
    local item = ITEMS[itemName]
    if not item then return false end

    if item.stackable then return removePlayerStackableItem(source, itemName, amount) end
    return removePlayerUniqueItem(source, itemName, amount, metaData)
end

--+--+--+--+--+--+--+ EXPORT OBJECT +--+--+--+--+--+--+--+

local Player = {}
Player.__index = Player

function Player.new(source)
    local self = setmetatable({}, Player)
    self.source = source
    return self
end

function Player:getUniques()
    return getPlayerUniques(self.source)
end

function Player:getStackables()
    return getPlayerStackables(self.source)
end

function Player:getInventory()
    return getPlayerInventory(self.source)
end

function Player:setUniques(uniques)
    setPlayerUniques(self.source, uniques)
end

function Player:setStackables(stackables)
    setPlayerStackables(self.source, stackables)
end

function Player:setInventory(inventory)
    setPlayerInventory(self.source, inventory)
end

function Player:canCarryItems(itemName, amount)
    local inventory = getPlayerInventory(self.source)
    local canCarry = canPlayerCarryItems(inventory, itemName, amount)
    local canFit = canPlayerFitItems(inventory, itemName, amount)
    return canCarry and canFit
end

function Player:giveStackable(itemName, amount)
    return givePlayerStackableItem(self.source, itemName, amount)
end

function Player:giveUnique(itemName, amount, metaData)
    return givePlayerUniqueItem(self.source, itemName, amount, metaData)
end

function Player:giveItem(itemName, amount, metaData)
    return givePlayerItem(self.source, itemName, amount, metaData)
end

function Player:doesPlayerHaveStackable(itemName, amount)
    local stackables = getPlayerStackables(self.source)
    return doStackablesIncludeItem(stackables, itemName, amount)
end

function Player:doesPlayerHaveUnique(itemName, metaData)
    local uniques = getPlayerUniques(self.source)
    return doUniquesIncludeItem(uniques, itemName, metaData)
end

function Player:doesPlayerHaveItem(itemName, amount, metaData)
    local inventory = getPlayerInventory(self.source)
    return doesInventoryIncludeItem(inventory, itemName, amount, metaData)
end

function Player:removeStackable(itemName, amount)
    return removePlayerStackableItem(self.source, itemName, amount)
end

function Player:removeUnique(itemName, metaData)
    return removePlayerUniqueItem(self.source, itemName, metaData)
end

function Player:removeItem(itemName, amount, metaData)
    return removePlayerItem(self.source, itemName, amount, metaData)
end