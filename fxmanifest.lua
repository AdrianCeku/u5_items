fx_version "cerulean"

game "gta5"

author "github.com/AdrianCeku"

description "ultimate5-items"

version "0.1b"

lua54 "yes"

shared_scripts{
	"shared/items.lua",
	"shared/sort.lua",
	"shared/exports.lua",
}

client_scripts{

}

server_scripts{
	"server/inventory.lua"
}

dependencies {
	"u5_sqlite"
}
