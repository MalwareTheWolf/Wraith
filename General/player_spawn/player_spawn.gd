@icon( "res://General/Icon/player_spawn.svg" )

class_name PlayerSpawn extends Node2D

func _ready() -> void:
	visible = false
	await get_tree().process_frame
	
	#Check for a player
	if get_tree().get_first_node_in_group( "Player" ):
		
		#player found
		print("Player Detected")
		return
	
	#no player found
	print("No Player Found")
	
	#instantiate
	var player : Player = load( "res://player/Scene/player.tscn" ).instantiate()
	get_tree().root.add_child( player )
	#position player
	player.global_position = self.global_position
	
	pass
