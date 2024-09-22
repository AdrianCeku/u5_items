fx_version "cerulean"

game "gta5"

author "github.com/AdrianCeku"

description "ultimate5-items"

version "0.1b"

lua54 "yes"

shared_scripts{

}

client_scripts{

}

server_scripts{
	"server/items.lua",
	"server/metadata.lua",
	"server/sort.lua",
	"server/exports.lua",
}

dependencies {
	"u5_sqlite"
}
