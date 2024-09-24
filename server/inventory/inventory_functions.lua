db = exports["u5_sqlite"]

local playerInventoryTableName = "player_inventory"
local containerInventoryTableName = "container_inventory"

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
            {"unique_items", "TEXT", "NOT NULL"}
        }
    )
end

--+--+--+--+--+--+--+ create / delete entries +--+--+--+--+--+--+--+

local function getPlayerId(source)
    return "license:5879eeedc4a81dfd713978626df5e93371b361c3"
    -- return GetPlayerIdentifierByType(source, "license")
end

local function createPlayerEntry(source)
    print("createPlayerEntry", source)
    db:insert(playerInventoryTableName, {player_id = getPlayerId(source), stackable_items = "{}", unique_items = "{}"})
end

local function createContainerEntry(containerName)
    db:insert(containerInventoryTableName, {container_name = container_name, stackable_items = "{}", unique_items = "{}"})
end

local deleteContainerEntry = function(containerName)
    db:delete(containerInventoryTableName, {container_name = container_name})
end

--+--+--+--+--+--+--+ get inventory +--+--+--+--+--+--+--+

-- player
local function getPlayerFromDb(source, columns)
    local result = db:select(playerInventoryTableName, columns, {player_id = getPlayerId(source)})
    if not result then createPlayerEntry(source) return {stackable_items = {}, uniques_items= {}} end
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
local function getContainerFromDb(containerName, columns)
    local result = db:select(containerInventoryTableName, columns, {container_name = containerName})
    if not result then createContainerEntry(containerName) return {stackable_items = {}, uniques_items= {}} end
    return result[1]
end

local function getContainerUniques(containerName)
    local result = getContainerFromDb(containerName, {"unique_items"})
    return json.decode(result.unique_items)
end

local function getContainerStackables(containerName)
    local result = getContainerFromDb(containerName, {"stackable_items"})
    return json.decode(result.stackable_items)
end

local function getContainerInventory(container_name)
    local result = getContainerFromDb(container_name, {"stackable_items", "unique_items"})
    if not result then createContainerEntry(container_name) return {stackables = {},  uniques= {}} end
    return {stackables = result.stackable_items, uniques = result.unique_items}
end

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
local function setContainerUniques(container_name, uniques)
    db:update(containerInventoryTableName, {unique_items = json.encode(uniques)}, {container_name = container_name})
end

local function setContainerStackables(container_name, stackables)
    db:update(containerInventoryTableName, {stackable_items = json.encode(stackables)}, {container_name = container_name})
end

local function setContainerInventory(container_name, inventory)
    db:update(containerInventoryTableName, {
        stackable_items = json.encode(inventory.stackables),
        unique_items = json.encode(inventory.uniques)
    }, {container_name = container_name})
end

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
            item = itemName,
            metaData = metaData
        } 
    )

    return uniques
end

-- player
local function givePlayerStackableItem(source, itemName, amount)
    local stackables = getPlayerStackables(source)
    print(json.encode(stackables))
    stackables = addToStackables(stackables, itemName, amount)
    print(json.encode(stackables))
    setPlayerStackables(source, stackables)
end

local function givePlayerUniqueItem(source, itemName, additionalMetaData)
    local uniques = getPlayerUniques(source)
    addToUniques(source, uniques, itemName, additionalMetaData)
    if uniques then setPlayerUniques(source, uniques) end
end

function givePlayerItem(source, itemName, amount, additionalMetaData)
    local item = ITEMS[itemName]
    if not item then 
        print("Item:\27[31m", itemName, "\27[0mdoes not exist")
        return 
    end

    if item.stackable then
        givePlayerStackableItem(source, itemName, amount)
    else
        for i=1, amount do
            givePlayerUniqueItem(source, itemName, additionalMetaData)
        end
    end
end


-- container
local function giveContainerStackableItem(container_name, itemName, amount)
    local stackables = getContainerStackables(container_name)
    stackables = addToStackables(stackables, itemName, amount)
    setContainerStackables(container_name, stackables)
end

local function giveContainerUniqueItem(container_name, itemName, additionalMetaData)
    local uniques = getContainerUniques(container_name)
    uniques = addToUniques(0, uniques, itemName, additionalMetaData)
    setContainerUniques(container_name, uniques)
end

function giveContainerItem(container_name, itemName, amount, additionalMetaData)
    local item = ITEMS[itemName]
    if not item then 
        print("Item:\27[31m", itemName, "\27[0mdoes not exist")
        return 
    end

    if item.stackable then
        giveContainerStackableItem(container_name, itemName, amount)
    else
        for i=1, amount do
            giveContainerUniqueItem(container_name, itemName, additionalMetaData)
        end
    end
end

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

local function doesMetaDataMatch(meta, metaDataToMatch)
    for key, value in pairs(matchMeta) do
        if not meta[key] then return false end
        if meta[key].value ~= value then return false end
    end

    return true
end

local function doUniquesIncludeItem(uniques, itemName, metaData)
    for i=1, #uniques do
        local item = uniques[i]

        if item.itemName == itemName then 
            if metaData then 
                if doesMetaDataMatch(item.metaData, metaData) then
                    return true, i
                end
            else
                return true, i
            end
        end
    end

    return false, nil
end

local function removeFromUniques(uniques, index)
    table.remove(uniques, index)
    return uniques
end

-- player
local function removePlayerStackable(source, itemName, amount)
    local stackables = getPlayerStackables(source)
    if not doStackablesIncludeItem(stackables, itemName, amount) then return false end
    stackables = removeFromStackables(stackables, itemName, amount)
    setPlayerStackables(source, stackables)
    return true
end

local function removePlayerUniqueItem(source, itemName, metaData)
    local uniques = getPlayerUniques(source)
    local hasItem, index = doUniquesIncludeItem(uniques, itemName, metaData)
    if not hasItem then return false end
    uniques = removeFromUniques(uniques, index)
    setPlayerUniques(source, uniques)
    return true
end

function removePlayerItem(source, itemName, amount, metaData)
    local item = ITEMS[itemName]
    if not item then 
        print("Item:\27[31m", itemName, "\27[0mdoes not exist")
        return 
    end

    if item.stackable then
        removePlayerStackable(source, itemName, amount)
    else
        for i=1, amount do
            if not removePlayerUniqueItem(source, itemName, metaData) then
                print("Player does not have item\27[31m", itemName, "\27[0mwith metaData\27[31m", json.encode(metaData))
            end
        end
    end
end