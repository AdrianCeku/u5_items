function getAllItems()
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

local function getItem(itemName)
    return ITEMS[itemName]
end