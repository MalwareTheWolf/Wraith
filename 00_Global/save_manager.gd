#save manager script
extends Node

var current_slot : int = 0
var save_data : Dictionary
var discovered_areas : Array = []
var persistent_data : Dictionary = {}



func _ready() -> void:
	
	pass

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			create_new_game_save()
		elif event.keycode == KEY_F7:
			load_game()
	pass


func create_new_game_save() -> void:
	var new_game_scene : String = "res://World/00_Void/01.tscn" #replace with cutscene later
	save_data = {
		"scene_path" : new_game_scene, 
		"x" : 100,
		"y" : -80,
		"hp" : 20,
		"max_hp" : 20,
		"dash" : false,
		"double_jump" : false,
		"lightning" : false,
		"Chain_lightning" : false,
		"dark_blast" : false,
		"heavy_attack" : false,
		"power_up" : false,
		"ground_slam" : false,
		"morph" : false,
		"spell2" : false,
		"spell3" : false,
		"spell4" : false,
		"spell5" : false,
		"spell6" : false,
		"spell7" : false,
		"spell8" : false,
		"discovered_areas" : [ new_game_scene],
		"persistent_data" : {},
	}
	#save game data
	var save_file = FileAccess.open( "user://save.sav", FileAccess.WRITE )
	save_file.store_line( JSON.stringify( save_data ) )
	pass


func save_game() -> void:
	print("save")
	var player :Player = get_tree().get_first_node_in_group( "Player" )
	save_data = {
		"scene_path" : SceneManager.current_scene_uid, 
		"x": player.global_position.x,
		"y": player.global_position.y,
		"hp": player.hp,
		"max_hp": player.max_hp,
		"dash": player.dash,
		"double_jump": player.double_jump,
		"lightning": player.lightning,
		"Chain_lightning": player.Chain_lightning,
		"dark_blast": player.dark_blast,
		"heavy_attack": player.heavy_attack,
		"power_up": player.power_up,
		"ground_slam": player.ground_slam,
		"morph": player.morph,
		"spell2": player.spell2,
		"spell3": player.spell3,
		"spell4": player.spell4,
		"spell5": player.spell5,
		"spell6": player.spell6,
		"spell7": player.spell7,
		"spell8": player.spell8,
		"discovered_areas" : discovered_areas,
		"persistent_data" : persistent_data,
	}
	var save_file = FileAccess.open( "user://save.sav", FileAccess.WRITE )
	save_file.store_line( JSON.stringify( save_data ) )
	pass


func load_game() -> void:
	print("load")
	pass
