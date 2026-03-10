extends TileMap
# Sends player back to title screen on spike tiles

@export var spike_key: String = "spikes"

func _physics_process(_delta: float) -> void:
	for player in get_tree().get_nodes_in_group("Player"):
		check_player_tile(player)


func check_player_tile(player) -> void:
	# Convert player's global position to TileMap local coordinates
	var local_pos = to_local(player.global_position)
	
	# Convert to map (grid) coordinates
	var map_pos: Vector2i = local_to_map(local_pos)
	
	# Get the tile ID at this map position
	var tile_id: int = get_cell_item(map_pos)
	if tile_id == -1:
		return # no tile here

	# Get the TileSet from this TileMap
	var ts = tile_set
	if ts == null:
		return

	# Get the custom data from the tile in the TileSet
	var tile_data = ts.tile_get_custom_data(tile_id)
	if tile_data == null:
		return

	# Check if the spike_key exists and is true
	if tile_data.has(spike_key) and tile_data[spike_key]:
		# Player hit spike
		player.global_position = player.respawn_position
		player.hp = player.max_hp
		Messages.back_to_title_screen.emit()
		print("Player hit spike! Returning to title screen.")
