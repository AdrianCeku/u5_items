local function checkType(value, expectedType, name)
    if type(value) ~= expectedType then
        print("Expected\27[31m", name, "\27[0mto be of type\27[31m", expectedType, "\27[0mgot\27[31m", type(value))
        return false
    end

    return true
end

local function checkItem(item, data)
    local errorMessage = "Error initializing:\27[31m"
    if not checkType(data.label, "string", "label") then print(errorMessage, item) return false end
    if not checkType(data.description, "string", "description") then print(errorMessage, item) return false end
    if not checkType(data.category, "string", "category") then print(errorMessage, item) return false end
    if not checkType(data.weight, "number", "weight") then print(errorMessage, item) return false end
    if not checkType(data.size, "table", "size") then print(errorMessage, item) return false end
    if not checkType(data.size.x, "number", "size.x") then print(errorMessage, item) return false end
    if not checkType(data.size.y, "number", "size.y") then print(errorMessage, item) return false end
    if not checkType(data.model, "string", "model") then print(errorMessage, item) return false end
    if not checkType(data.stackable, "boolean", "stackable") then print(errorMessage, item) return false end

    if not checkType(data.usable, "boolean", "usable") then print(errorMessage, item) return false end
    if data.usable then
        if not checkType(data.useOptions, "table", "useOptions") then print(errorMessage, item) return false end
        if not checkType(data.useOptions.removeAfterUse, "number", "useOptions.removeAfterUse") then print(errorMessage, item) return false end
        if not checkType(data.useOptions.duration, "number", "useOptions.duration") then print(errorMessage, item) return false end
    end

    if not checkType(data.craftable, "boolean", "craftable") then print(errorMessage, item) return false end
    if data.craftable then
        if not checkType(data.craftOptions, "table", "craftOptions") then print(errorMessage, item) return false end
        if not checkType(data.craftOptions.ingredients, "table", "craftOptions.ingredients") then print(errorMessage, item) return false end
        if not checkType(data.craftOptions.duration, "number", "craftOptions.duration") then print(errorMessage, item) return false end
        if not checkType(data.craftOptions.resultAmount, "number", "craftOptions.resultAmount") then print(errorMessage, item) return false end
    end

    if not checkType(data.canBuy, "boolean", "canBuy") then print(errorMessage, item) return false end
    if data.canBuy then
        if not checkType(data.prices, "table", "prices") then print(errorMessage, item) return false end
        if not checkType(data.prices.fiat, "table", "prices.fiat") then print(errorMessage, item) return false end
        if not checkType(data.prices.fiat.buy, "number", "prices.fiat.buy") then print(errorMessage, item) return false end
        if not checkType(data.prices.black, "table", "prices.black") then print(errorMessage, item) return false end
        if not checkType(data.prices.black.buy, "number", "prices.black.buy") then print(errorMessage, item) return false end
    end

    if not checkType(data.canSell, "boolean", "canSell") then print(errorMessage, item) return false end
    if data.canSell then
        if not checkType(data.prices, "table", "prices") then print(errorMessage, item) return false end
        if not checkType(data.prices.fiat, "table", "prices.fiat") then print(errorMessage, item) return false end
        if not checkType(data.prices.fiat.sell, "number", "prices.fiat.sell") then print(errorMessage, item) return false end
        if not checkType(data.prices.black, "table", "prices.black") then print(errorMessage, item) return false end
        if not checkType(data.prices.black.sell, "number", "prices.black.sell") then print(errorMessage, item) return false end
    end

    return true
end

local function addMetaData(item, name, showToPlayer, onSpawn, onUse, onDrop, onPickup)
    if not ITEMS[item] then
        print("Item\27[31m", item, "\27[0mdoes not exist")
        return
    end

    if ITEMS[item].stackable then
        print("Item\27[31m", item, "\27[0mis stackable. MetaData can only be added to non-stackable items!")
        return
    end

    if ITEMS[item].metaData[name] then
        print("MetaData\27[31m", name, "\27[0malready exists for item", item)
        return
    end

    ITEMS[item].metaData[name] = {
        showToPlayer = showToPlayer,
        onSpawn = onSpawn,
        onUse = onUse,
        onDrop = onDrop,
        onPickup = onPickup
    }
end

local function initializeItem(item, data)
    ITEMS[item].metaData = {}

    if ITEM_METADATA[item] then
        for name, metaData in pairs(ITEM_METADATA[item]) do
            addMetaData(item, name, metaData.showToPlayer, metaData.onSpawn, metaData.onUse, metaData.onDrop, metaData.onPickup)
        end
    end

    if not CATEGORIES[data.category] then
        CATEGORIES[data.category] = {}
    end

    table.insert(CATEGORIES[data.category], item)

    if data.usable then
        table.insert(USABLE_ITEMS, item)
    end

    if data.craftable then
        table.insert(CRAFTABLE_ITEMS, item)
    end

    if data.canBuy then
        table.insert(BUYABLE_ITEMS, item)
    end

    if data.canSell then
        table.insert(SELLABLE_ITEMS, item)
    end
end

local function addItem(item, data)
    if ITEMS[item] then
        print("Item", item, "already exists")
        return
    end

    if checkItem(item, data) then 
        ITEMS[item] = data
        initializeItem(item, data) 
    end
end

for item, data in pairs(ITEMS) do
    if checkItem(item, data) then initializeItem(item, data) end
end

-- print("Items:",
--     json.encode(
--         getItemsTable()
--     )
-- )

-- print("Items by category:",
--     json.encode(
--         getItemsByCategory("food")
--     )
-- )

-- print("Usable items:",
--     json.encode(
--         getUsableItems()
--     )
-- )

-- print("Craftable items:",
--     json.encode(
--         getCraftableItems()
--     )
-- )

-- print("Buyable items:",
--     json.encode(
--         getBuyableItems()
--     )
-- )

-- print("Sellable items:",
--     json.encode(
--         getSellableItems()
--     )
-- )