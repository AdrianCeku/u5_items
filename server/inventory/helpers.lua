db = exports["u5_sqlite"]
local emptyInventoryEntry = {stackable_items = "{}", unique_items = "{}"}

function getInventoryWeight(inventory)
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

function getSlotsOccupied(inventory)
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

function addToStackables(stackables, itemName, amount)
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

function addToUniques(source, uniques, itemName, additionalMetaData)
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

function removeFromStackables(stackables, itemName, amount)
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

function doesMetaIncludeKeysAndValues(meta, keysAndValues)
    if not keysAndValues then return true end
    if not meta then return false end

    for key, value in pairs(keysAndValues) do
        if not meta[key] then return false end
        if meta[key].value ~= value then return false end
    end

    return true
end