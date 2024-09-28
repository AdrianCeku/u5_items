local containerInventoryTableName = "container_inventory"

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
--todo

--+--+--+--+--+--+--+ remove item +--+--+--+--+--+--+--+
--todo

--+--+--+--+--+--+--+ EXPORT OBJECT +--+--+--+--+--+--+--+

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