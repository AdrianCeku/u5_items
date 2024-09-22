CATEGORIES = {}
USABLE_ITEMS = {}
CRAFTABLE_ITEMS = {}
BUYABLE_ITEMS = {}
SELLABLE_ITEMS = {}

local function checkType(value, expectedType, name)
    if type(value) ~= expectedType then
        print("Expected", name, "to be of type", expectedType, "got", type(value))
        return false
    end

    return true
end

local function checkItem(item, data)
    local errorMessage = "Error initializing: "
    if not checkType(data.label, "string", "label") then print(errorMessage, item) return false end
    if not checkType(data.description, "string", "description") then print(errorMessage, item) return false end
    if not checkType(data.category, "string", "category") then print(errorMessage, item) return false end
    if not checkType(data.weight, "number", "weight") then print(errorMessage, item) return false end
    if not checkType(data.size, "table", "size") then print(errorMessage, item) return false end
    if not checkType(data.size.x, "number", "size.x") then print(errorMessage, item) return false end
    if not checkType(data.size.y, "number", "size.y") then print(errorMessage, item) return false end
    if not checkType(data.model, "string", "model") then print(errorMessage, item) return false end
    if not checkType(data.unique, "boolean", "unique") then print(errorMessage, item) return false end

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

local function initializeItem(item, data)
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

    data.metaData = {}

    return true
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

local function getItemsTable()
    return ITEMS
end

local function getItemsByCategory(category)
    return CATEGORIES[category]
end

local function getUsableItems()
    return USABLE_ITEMS
end

local function getCraftableItems()
    return CRAFTABLE_ITEMS
end

local function getBuyableItems()
    return BUYABLE_ITEMS
end

local function getSellableItems()
    return SELLABLE_ITEMS
end

local function addMetaDataOnItemCreation(item, name, showToPlayer, getFunction)
    if not ITEMS[item] then
        print("Item", item, "does not exist")
        return
    end

    if ITEMS[item].metaData[name] then
        print("MetaData", name, "already exists for item", item)
        return
    end

    ITEMS[item].metaData[name] = {
        showToPlayer = showToPlayer,
        getFunction = getFunction
    }
end

for item, data in pairs(ITEMS) do
    if checkItem(item, data) then initializeItem(item, data) end
end