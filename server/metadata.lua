ITEM_METADATA = {
--+--+--+--+--+--+--+ START +--+--+--+--+--+--+--+

    ["reusable_water_bottle"] = {
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
        },
    },

    ["id_card"] = {
        name = {
            showToPlayer = true,
            
            onSpawn = function(source) 
                return "John Doe"
            end,
        },
        birthdate = {
            showToPlayer = true,
            
            onSpawn = function(source) 
                return "01.01.1970"
            end,
        },
        uid = {
            showToPlayer = false,
            
            onSpawn = function(source) 
                return "1234567890"
            end,
        },
    },

--+--+--+--+--+--+--+ END +--+--+--+--+--+--+--+
}

    -- ["example"] = {
    --     value1 = {
    --         showToPlayer = true,
            
    --         onSpawn = function(source) 
    --             return 1000
    --         end,

    --         onUse = function(source, oldValue) 
    --             if oldValue - 100 <= 0 then
    --                 return 0
    --             end
    --             return oldValue - 100
    --         end,

    --         onDrop = function(source, oldValue) 
    --             return oldValue
    --         end,

    --         onPickup = function(source, oldValue) 
    --             return oldValue
    --         end
    --     },
    --     value2 = {
    --         showToPlayer = true,
            
    --         onSpawn = function(source) 
    --             return "example"
    --         end,

    --         onUse = function(source, oldValue) 
    --             return oldValue
    --         end,

    --         onDrop = function(source, oldValue) 
    --             return oldValue
    --         end,

    --         onPickup = function(source, oldValue) 
    --             return oldValue
    --         end
    --     },
    -- },