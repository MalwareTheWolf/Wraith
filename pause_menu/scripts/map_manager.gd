extends Node

var current_region: String = ""
var current_room_id: String = ""

var discovered_rooms: Dictionary = {}
var visited_rooms: Dictionary = {}

var region_display_names: Dictionary = {
	"wraith_woods": "Wraith Woods",
	"ruins": "Ruins",
	"crypt": "Crypt",
	"village": "Village"
}

var region_colors: Dictionary = {
	"wraith_woods": {
		"fill": Color("1a231f"),
		"border": Color("4ecb8f")
	},
	"ruins": {
		"fill": Color("2a241c"),
		"border": Color("d0a85c")
	},
	"crypt": {
		"fill": Color("1f1830"),
		"border": Color("b070ff")
	},
	"village": {
		"fill": Color("1d2230"),
		"border": Color("73b8ff")
	}
}

func visit_room(room_id: String, region_name: String) -> void:
	current_room_id = room_id
	current_region = region_name
	discovered_rooms[room_id] = true
	visited_rooms[room_id] = true

func discover_room(room_id: String) -> void:
	discovered_rooms[room_id] = true

func discover_rooms(room_ids: Array[String]) -> void:
	for room_id in room_ids:
		discovered_rooms[room_id] = true

func is_room_discovered(room_id: String) -> bool:
	return discovered_rooms.get(room_id, false)

func is_room_visited(room_id: String) -> bool:
	return visited_rooms.get(room_id, false)

func get_region_colors(region_name: String) -> Dictionary:
	return region_colors.get(region_name, {
		"fill": Color("222222"),
		"border": Color("aaaaaa")
	})

func get_region_display_name(region_name: String) -> String:
	return region_display_names.get(region_name, region_name.capitalize())
