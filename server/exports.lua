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

--+--+--+--+--+--+--+ PLAYERS +--+--+--+--+--+--+--+

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

--+--+--+--+--+--+--+ CONTAINERS +--+--+--+--+--+--+--+

local Container = {}
Container.__index = Container

function Container.new(name)
    local self = setmetatable({}, Container)
    local container = getContainerMeta(name)

    if container then
        self.name = name
        self.label = container.label
        self.sizeX = container.sizeX
        self.sizeY = container.sizeY
        self.maxWeight = container.maxWeight
    end

    return self
end

function Container:create(label, sizeX, sizeY, maxWeight)
    createContainerEntry(self.name, label, sizeX, sizeY, maxWeight)
end

function Container:delte()
    deleteContainerEntry(self.name)
end

function Container:getUniques()
    return getContainerUniques(self.name)
end

function Container:getStackables()
    return getContainerStackables(self.name)
end

function Container:getInventory()
    return getContainerInventory(self.name)
end

function Container:getSize()
    return {
        x = self.sizeX,
        y = self.sizeY
    }
end

function Container:getLabel()
    return self.label
end

function Container:getMaxWeight()
    return self.maxWeight
end

function Container:getMeta()
    return {
        label = self.label,
        sizeX = self.sizeX,
        sizeY = self.sizeY,
        maxWeight = self.maxWeight
    }
end

function Container:setUniques(uniques)
    setContainerUniques(self.name, uniques)
end

function Container:setStackables(stackables)
    setContainerStackables(self.name, stackables)
end

function Container:setInventory(inventory)
    setContainerInventory(self.name, inventory)
end