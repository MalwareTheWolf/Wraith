extends Control
class_name MapView

var map_data: Dictionary = {}
var current_room_id: String = ""

func set_map_data(new_map_data: Dictionary, new_current_room_id: String) -> void:
	map_data = new_map_data
	current_room_id = new_current_room_id
	queue_redraw()

func _draw() -> void:
	if map_data.is_empty():
		return

	if !map_data.has("rooms"):
		return

	var rooms: Dictionary = map_data["rooms"]

	# draw connections first
	for room_id in rooms.keys():
		var room: Dictionary = rooms[room_id]

		if !room.get("discovered", false):
			continue

		var room_center := room["pos"] + room["size"] * 0.5

		for connected_id in room.get("connections", []):
			if !rooms.has(connected_id):
				continue

			var connected_room: Dictionary = rooms[connected_id]
			if !connected_room.get("discovered", false):
				continue

			var connected_center := connected_room["pos"] + connected_room["size"] * 0.5
			draw_line(room_center, connected_center, Color(0.4, 0.8, 0.6), 2.0)

	# draw rooms
	for room_id in rooms.keys():
		var room: Dictionary = rooms[room_id]

		if !room.get("discovered", false):
			continue

		var rect := Rect2(room["pos"], room["size"])

		var fill_color := Color(0.15, 0.15, 0.15)
		var border_color := Color(0.3, 0.8, 0.5)

		if room_id == current_room_id:
			fill_color = Color(0.35, 0.1, 0.45)
			border_color = Color(1.0, 0.4, 1.0)
		elif room.get("visited", false):
			fill_color = Color(0.12, 0.22, 0.18)

		draw_rect(rect, fill_color, true)
		draw_rect(rect, border_color, false, 2.0)
