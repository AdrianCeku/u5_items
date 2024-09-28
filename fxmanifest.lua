fx_version "cerulean"

game "gta5"

author "github.com/AdrianCeku"

description "ultimate5-items"

version "0.1b"

lua54 "yes"

shared_scripts{
	"shared/config.lua",
	"shared/items.lua",
}

client_scripts{

}

server_scripts{
	"server/metadata.lua",
	"server/items_init.lua",
	"server/inventory/inventory_functions.lua",
	"server/inventory/inventory.lua",
	"server/exports.lua",
}

dependencies {
	"u5_sqlite"
}
