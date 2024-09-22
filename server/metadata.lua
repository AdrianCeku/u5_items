ITEM_METADATA = {
    ["water_bottle"] = {
        amount = {
            showToPlayer = true,
            
            onSpawn = function(source) 
                return 1000
            end,

            onUse = function(source, oldValue) 
                if oldValue - 100 <= 0 then
                    return 0
                end
                return oldValue - 100
            end,

            -- onDrop = function(source, oldValue) 
            --     return oldValue
            -- end,

            -- onPickup = function(source, oldValue) 
            --     return oldValue
            -- end
        }
    }
}