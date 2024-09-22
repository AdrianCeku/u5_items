CATEGORIES = {}
USABLE_ITEMS = {}
CRAFTABLE_ITEMS = {}
BUYABLE_ITEMS = {}
SELLABLE_ITEMS = {}

ITEMS = {
--+--+--+--+--+--+--+ START +--+--+--+--+--+--+--+


--+--+--+--+--+--+--+ Food / Drinks +--+--+--+--+--+--+--+
    ["water_bottle"] = {
        label = "Water Bottle",
        description = "A bottle of water.",
        category = "food",
        weight = 1,
        size = {x = 1, y = 3},
        model = "prop_ld_flow_bottle",
        stackable = true,
        usable = true,
        useOptions = {
            removeAfterUse = 1,
            duration = 2000,
        },
        craftable = true,
        craftOptions = {
            ingredients = {
                ["plastic_bottle"] = 1,
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


--+--+--+--+--+--+--+ END +--+--+--+--+--+--+--+
}