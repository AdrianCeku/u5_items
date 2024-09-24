db = exports["u5_sqlite"]

local playerInventoryTableName = "player_inventory"
local containerInventoryTableName = "container_inventory"
local emptyPlayerEntry = {stackable_items = "{}", unique_items = "{}"}

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
            {"stackable_items", "TEXT", "NOT NULL"},
            {"unique_items", "TEXT", "NOT NULL"},
            {"size_x", "INTEGER", "NOT NULL"},
            {"size_y", "INTEGER", "NOT NULL"},
            {"max_weight", "INTEGER", "NOT NULL"}
        }
    )
end

--+--+--+--+--+--+--+ create / delete entries +--+--+--+--+--+--+--+

local function getPlayerId(source)
    return "license:5879eeedc4a81dfd713978626df5e93371b361c3"
    -- return GetPlayerIdentifierByType(source, "license")
end

local function createPlayerEntry(source)
    db:insert(playerInventoryTableName, {
        player_id = getPlayerId(source), 
        stackable_items = "{}", 
        unique_items = "{}"}
    )
end

local function createContainerEntry(containerName, sizeX, sizeY, maxWeight)
    db:insert(containerInventoryTableName, {
        container_name = container_name, 
        stackable_items = "{}", 
        unique_items = "{}",
        size_x = sizeX,
        size_y = sizeY,
        max_weight = maxWeight
        }
    )
end

local deleteContainerEntry = function(containerName)
    db:delete(containerInventoryTableName, {container_name = container_name})
end

--+--+--+--+--+--+--+ get inventory +--+--+--+--+--+--+--+

-- player
local function getPlayerFromDb(source, columns)
    local result = db:select(playerInventoryTableName, columns, {player_id = getPlayerId(source)})
    if not result then createPlayerEntry(source) return {stackable_items = "{}", uniques_items= "{}"} end
    return result[1]
end

local function getPlayerUniques(source)
    local result = getPlayerFromDb(source, {"unique_items"})
    return json.decode(result.unique_items)
end

local function getPlayerStackables(source)
    local result = getPlayerFromDb(source, {"stackable_items"})
    return json.decode(result.stackable_items)
end

local function getPlayerInventory(source)
    local result = getPlayerFromDb(source, {"stackable_items", "unique_items"})
    return {stackables = result.stackable_items, uniques = result.unique_items}
end

-- container
--todo

--+--+--+--+--+--+--+ set inventory +--+--+--+--+--+--+--+

-- player
local function setPlayerUniques(source, uniques)
    db:update(playerInventoryTableName, {unique_items = json.encode(uniques)}, {player_id = getPlayerId(source)})
end

local function setPlayerStackables(source, stackables)
    print("setPlayerStackables", source, json.encode(stackables))
    db:update(playerInventoryTableName, {stackable_items = json.encode(stackables)}, {player_id = getPlayerId(source)})
end

local function setPlayerInventory(source, inventory)
    db:update(playerInventoryTableName, {
        stackable_items = json.encode(inventory.stackables),
        unique_items = json.encode(inventory.uniques)
    }, {player_id = getPlayerId(source)})
end

-- container
-- todo
--+--+--+--+--+--+--+ give item +--+--+--+--+--+--+--+

-- helper
local function addToStackables(stackables, itemName, amount)
    local maxStack = ITEMS[itemName].maxStack
    local stacks = stackables[itemName]
    local leftOver = amount

    if maxStack <= 0 then 
        if not stacks then 
            stackables[itemName] = {amount}
        else 
            stackables[itemName] = {stacks[1] + amount} 
        end

        return stackables 
    end

    if stacks then
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
    else 
        stackables[itemName] = {}

        while leftOver > 0 do
            if leftOver <= maxStack then
                table.insert(stackables[itemName], leftOver)
                return stackables
            else
                table.insert(stackables[itemName], maxStack)
                leftOver = leftOver - maxStack
            end
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

-- player
local function givePlayerStackableItem(source, itemName, amount)
    local stackables = getPlayerStackables(source)
    stackables = addToStackables(stackables, itemName, amount)
    setPlayerStackables(source, stackables)
end

local function givePlayerUniqueItem(source, itemName, amount, additionalMetaData)
    local uniques = getPlayerUniques(source)
    for i=1, amount do
        uniques = addToUniques(source, uniques, itemName, additionalMetaData)
    end
    setPlayerUniques(source, uniques)
end

function givePlayerItem(source, itemName, amount, additionalMetaData)
    local item = ITEMS[itemName]
    if not item then return end

    if item.stackable then
        return givePlayerStackableItem(source, itemName, amount)
    else
        return givePlayerUniqueItem(source, itemName, amount, additionalMetaData)
    end
end


-- container
-- todo

--+--+--+--+--+--+--+ remove item +--+--+--+--+--+--+--+

-- helper
local function doStackablesIncludeItem(stackables, itemName, amount)
    local stacks = stackables[itemName]
    local leftOver = amount
    
    if stacks then
        for i=1, #stacks do
            if stacks[i] >= leftOver then return true end
            leftOver = leftOver - stacks[i]
        end
    end

    return false
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

local function doUniquesIncludeItem(uniques, itemName, metaData)
    for i=1, #uniques do
        local item = uniques[i]

        if item.itemName == itemName and doesMetaIncludeKeysAndValues(item.metaData, metaData) then
            return true, i
        end
    end

    return false, nil
end

-- player
local function removePlayerStackable(source, itemName, amount)
    local stackables = getPlayerStackables(source)
    if not doStackablesIncludeItem(stackables, itemName, amount) then return false end
    stackables = removeFromStackables(stackables, itemName, amount)
    setPlayerStackables(source, stackables)
    return true
end

local function removePlayerUniqueItem(source, itemName, amount, metaData)
    local uniques = getPlayerUniques(source)

    for i=1, amount do 
        local hasItem, index = doUniquesIncludeItem(uniques, itemName, metaData)
        print("hasItem", hasItem, "index", index)
        print(json.encode(uniques))
        if not hasItem then return false end
        table.remove(uniques, index)
    end

    setPlayerUniques(source, uniques)
    return true
end

function removePlayerItem(source, itemName, amount, metaData)
    local item = ITEMS[itemName]
    if not item then return false end

    if item.stackable then
        return removePlayerStackable(source, itemName, amount)
    else
        return removePlayerUniqueItem(source, itemName, amount, metaData)
    end
end