ITEM_METADATA = {
    ["water_bottle"] = {
        amount = {
            showToPlayer = true,
            
            onSpawn = function(source) 
                return 500
            end,

            onUse = function(source, oldValue) 
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