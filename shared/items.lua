CATEGORIES = {}
USABLE_ITEMS = {}
CRAFTABLE_ITEMS = {}
BUYABLE_ITEMS = {}
SELLABLE_ITEMS = {}

ITEMS = {
--+--+--+--+--+--+--+ START +--+--+--+--+--+--+--+


--+--+--+--+--+--+--+ Food / Drinks +--+--+--+--+--+--+--+
    ["reusable_water_bottle"] = {
        label = "Water Bottle",
        description = "A bottle of water.",
        category = "food",
        weight = 500,
        size = {x = 1, y = 3},
        model = "h4_prop_battle_waterbottle_01a",
        stackable = false,
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
                buy = 200,
                sell = 100,
            },
        }
    },

    ["donut"] = {
        label = "Donut",
        description = "A tasty donut.",
        category = "food",
        weight = 1,
        size = {x = 1, y = 1},
        model = "prop_donut_02b",
        stackable = true,
        maxStack = 10,
        usable = true,
        useOptions = {
            removeAfterUse = 1,
            duration = 2000,
        },
        craftable = false,
        craftOptions = {},
        canBuy = true,
        canSell = true,
        prices = {
            fiat = {
                buy = 30,
                sell = 15,
            },
        }
    },

--+--+--+--+--+--+--+ licenses +--+--+--+--+--+--+--+

["id_card"] = {
    label = "ID Card",
    description = "",
    category = "licenses",
    weight = 1,
    size = {x = 1, y = 1},
    model = "p_ld_id_card_01",
    stackable = false,
    usable = true,
    useOptions = {
        removeAfterUse = 0,
        duration = 2000,
    },
    craftable = false,
    craftOptions = {},
    canBuy = true,
    canSell = false,
    prices = {
        fiat = {
            buy = 300,
        },
        black = {
            buy = 1000,
        }
    }
},

--+--+--+--+--+--+--+ licenses +--+--+--+--+--+--+--+

--+--+--+--+--+--+--+ END +--+--+--+--+--+--+--+
}