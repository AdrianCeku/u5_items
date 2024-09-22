ITEMS = {
--+--+--+--+--+--+--+ Food / Drinks +--+--+--+--+--+--+--+
    ["water_bottle"] = {
        label = "Water Bottle",
        description = "A bottle of water.",
        category = "food",
        weight = 1,
        size = {x = 1, y = 1},
        model = "prop_ld_flow_bottle",
        unique = false,
        usable = true,
        useOptions = {
            removeAfterUse = 1,
            duration = 2000,
        },
        craftable = true,
        craftOptions = {
            ingredients = {
                ["plastic"] = 1,
                ["water"] = 1,
            },
            duration = 5000,
            resultAmount = 1,
        },
        canBuy = true,
        canSell = true,
        prices = {
            fiat = {
                buy = 5,
                sell = 2,
            },
            black = {
                buy = 10,
                sell = 5,
            }
        }
    },

--+--+--+--+--+--+--+ Food / Drinks +--+--+--+--+--+--+--+
}