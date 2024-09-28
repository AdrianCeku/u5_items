db = exports["u5_sqlite"]

local playerInventoryTableName = "player_inventory"
local containerInventoryTableName = "container_inventory"
local emptyInventoryEntry = {stackable_items = "{}", unique_items = "{}"}

function initTables()
    db:createTable(playerInventoryTableName,
        {
            {"player_id", "STRING", "PRIMARY KEY NOT NULL"},
            {"stackable_items", "TEXT", "NOT NULL"},
            {"unique_items", "TEXT", "NOT NULL"}
        }
    )

    db:createTable(containerInventoryTableName,
        {
            {"container_name", "STRING", "AUTO PRIMARY KEY NOT NULL"},
            {"label", "STRING"},
            {"stackable_items", "TEXT", "NOT NULL"},
            {"unique_items", "TEXT", "NOT NULL"},
            {"size_x", "INTEGER", "NOT NULL"},
            {"size_y", "INTEGER", "NOT NULL"},
            {"max_weight", "INTEGER", "NOT NULL"}
        }
    )
end
--+--+--+--+--+--+--+ HELPERS +--+--+--+--+--+--+--+

local function getInventoryWeight(inventory)
    local stackables = inventory.stackables
    local uniques = inventory.uniques
    local weight = 0

    for itemName, stacks in pairs(stackables) do
        local item = ITEMS[itemName]
        local amount = 0

        for i=1, #stacks do
            amount = amount + stacks[i]
        end

        weight = weight + amount * item.weight
    end

    for i=1, #uniques do
        local item = ITEMS[uniques[i].itemName]
        weight = weight + item.weight
    end
end

local function getSlotsOccupied(inventory)
    local stackables = inventory.stackables
    local uniques = inventory.uniques
    local slots = 0

    for itemName, stacks in pairs(stackables) do
        local item = ITEMS[itemName]
        slots = slots + (#stacks * item.size.x * item.size.y)
    end

    for i=1, #uniques do
        local item = ITEMS[uniques[i].itemName]
        slots = slots + (item.size.x * item.size.y)
    end

    return slots
end

function canContainerCarryItems(maxWeight, inventory, itemName, amount)
    local inventoryWeight = getInventoryWeight(inventory)
    local item = ITEMS[itemName]
    local stackables = inventory.stackables
    local uniques = inventory.uniques

    if inventoryWeight + (item.weight * amount) <= maxWeight then 
        return true 
    end

    return false
end

function canPlayerCarryItems(inventory, itemName, amount)
    return canContainerCarryItems(Config.maxWeight, inventory, itemName, amount)
end

function canContainerFitItems(sizeX, sizeY, inventory, itemName, amount)
    local slotsOccupied = getSlotsOccupied(inventory)
    local item = ITEMS[itemName]
    local maxSlots = sizeX * sizeY
    local stackables = inventory.stackables

    if not item.stackable then
        if slotsOccupied + (item.size.x * item.size.y * amount) > maxSlots then return false end
    else
        inventory.stackables = addToStackables(stackables, itemName, amount)
        if getSlotsOccupied(inventory) > maxSlots then return false end
    end

    return true
end

function canPlayerFitItems(inventory, itemName, amount)
    return canContainerFitItems(Config.inventorySizeX, Config.inventorySizeY, inventory, itemName, amount)
end

local function addToStackables(stackables, itemName, amount)
    local maxStack = ITEMS[itemName].maxStack
    local leftOver = amount

    if not stackables[itemName] then 
        stackables[itemName] = {0}
    end
    
    local stacks = stackables[itemName]
    
    -- MaxStack 0 means infinite stack
    if maxStack <= 0 then 
        stackables[itemName] = {stacks[1] + amount} 
        return stackables 
    end

    for i=1, #stacks do
        local stackAmount = stacks[i]

        if stackAmount < maxStack then
            local spaceLeft = maxStack - stackAmount
            
            if leftOver <= spaceLeft then
                stacks[i] = stackAmount + leftOver
                return stackables
            else
                stacks[i] = maxStack
                leftOver = leftOver - spaceLeft
            end
        end
    end

    while leftOver > 0 do
        if leftOver <= maxStack then
            table.insert(stackables[itemName], leftOver)
            return stackables
        else
            table.insert(stackables[itemName], maxStack)
            leftOver = leftOver - maxStack
        end
    end

    return stackables
end

local function addToUniques(source, uniques, itemName, additionalMetaData)
    local item = ITEMS[itemName]
    local metaData = additionalMetaData or {}

    if item.metaData then
        for name, data in pairs(item.metaData) do
            if metaData[name] then 
                print("Metadata\27[31m", name, "\27[0malready exists on\27[31m", itemName) 
            else
                metaData[name] = {
                    showToPlayer = data.showToPlayer,
                    value = data.onSpawn(source),
                }
            end
        end
    end

    table.insert(uniques, {
            itemName = itemName,
            metaData = metaData
        } 
    )

    return uniques
end

function doStackablesIncludeItem(stackables, itemName, amount)
    local stacks = stackables[itemName]
    if not stacks then return false end
    local leftOver = amount
    
    for i=1, #stacks do
        if stacks[i] >= leftOver then return true end
        leftOver = leftOver - stacks[i]
    end

    return false
end

function doUniquesIncludeItem(uniques, itemName, metaData)
    for i=1, #uniques do
        local item = uniques[i]

        if item.itemName == itemName and doesMetaIncludeKeysAndValues(item.metaData, metaData) then
            return true, i
        end
    end

    return false, nil
end

function doesInventoryIncludeItem(inventory, itemName, amount, metaData)
    local stackables = inventory.stackables
    local uniques = inventory.uniques
    local item = ITEMS[itemName]

    if item.stackable then return doStackablesIncludeItem(stackables, itemName, amount) end
    return doUniquesIncludeItem(uniques, itemName, metaData)
end

local function removeFromStackables(stackables, itemName, amount)
    local stacks = stackables[itemName]
    local leftOver = amount
    local stacksAmount = #stacks

    for i=1, stacksAmount do
        local reverseIndex = stacksAmount - i + 1
        local stack = stacks[reverseIndex]

        if stack > leftOver then
            stackables[itemName][reverseIndex] = stack - leftOver
            return stackables
        else
            leftOver = leftOver - stack
            table.remove(stackables[itemName], reverseIndex)
            if leftOver == 0 then return stackables end
        end
    end

    return stackables
end

local function doesMetaIncludeKeysAndValues(meta, keysAndValues)
    if not keysAndValues then return true end
    if not meta then return false end

    for key, value in pairs(keysAndValues) do
        if not meta[key] then return false end
        if meta[key].value ~= value then return false end
    end

    return true
end

--+--+--+--+--+--+--+ PLAYERS +--+--+--+--+--+--+--+
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



--+--+--+--+--+--+--+ CONTAINERS +--+--+--+--+--+--+--+
--+--+--+--+--+--+--+ create / delete +--+--+--+--+--+--+--+
function createContainerEntry(containerName, label, sizeX, sizeY, maxWeight)
    db:insert(containerInventoryTableName, {
        container_name = container_name,
        label = label,
        stackable_items = emptyInventoryEntry.stackable_items, 
        unique_items = emptyInventoryEntry.unique_items,
        size_x = sizeX,
        size_y = sizeY,
        max_weight = maxWeight
        }
    )
end

function deleteContainerEntry(containerName)
    db:delete(containerInventoryTableName, {container_name = container_name})
end

--+--+--+--+--+--+--+ get inventory +--+--+--+--+--+--+--+

local function getContainerFromDb(containerName, columns)
    local result = db:select(containerInventoryTableName, columns, {container_name = containerName})
    if not result then return end
    return result[1]
end

function getContainerUniques(containerName)
    local result = getContainerFromDb(containerName, {"unique_items"})
    if not result then return end
    return json.decode(result.unique_items)
end

function getContainerStackables(containerName)
    local result = getContainerFromDb(containerName, {"stackable_items"})
    if not result then return end
    return json.decode(result.stackable_items)
end

function getContainerInventory(containerName)
    local result = getContainerFromDb(containerName, {"stackable_items", "unique_items"})
    if not result then return end
    return {stackables = json.decode(result.stackable_items), uniques = json.decode(result.unique_items)}
end

function getContainerMeta(containerName)
    local result = getContainerFromDb(containerName, {"size_x", "size_y", "max_weight", "label"})
    if not result then return end
    return {
        sizeX = result.size_x, 
        sizeY = result.size_y,
        maxWeight = result.max_weight,
        label = result.label
    }
end

--+--+--+--+--+--+--+ set inventory +--+--+--+--+--+--+--+

function setContainerUniques(containerName, uniques)
    db:update(containerInventoryTableName, {unique_items = json.encode(uniques)}, {container_name = containerName})
end

function setContainerStackables(containerName, stackables)
    db:update(containerInventoryTableName, {stackable_items = json.encode(stackables)}, {container_name = containerName})
end

function setContainerInventory(containerName, inventory)
    db:update(containerInventoryTableName, {
        stackable_items = json.encode(inventory.stackables),
        unique_items = json.encode(inventory.uniques)
    }, {container_name = containerName})
end

--+--+--+--+--+--+--+ give item +--+--+--+--+--+--+--+


--+--+--+--+--+--+--+ remove item +--+--+--+--+--+--+--+
--todo