extends CanvasLayer

#region --- ONREADY VARIABLES
@onready var hp_margin_container: MarginContainer = %HPMarginContainer
@onready var hp_bar: TextureProgressBar = %HPBar

@onready var game_over: Control = %GameOver
@onready var load_button: Button = %LoadButton
@onready var quit_button: Button = %QuitButton

@onready var Debug_Menu: Control = $Debug_Menu  # Your new debug menu
#endregion

func _ready() -> void:
	# --- Hide debug menu by default ---
	if Debug_Menu:
		Debug_Menu.visible = false
		pass

	# Connect health update signal
	Messages.player_health_changed.connect(update_health_bar)
	
	# Setup game over UI
	game_over.visible = false
	load_button.pressed.connect(_on_load_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	pass

func update_health_bar(hp: float, max_hp: float) -> void:
	var value: float = (hp / max_hp) * 100
	hp_bar.value = value
	hp_margin_container.size.x = max_hp + 22
	pass

func show_game_over() -> void:
	load_button.visible = false
	quit_button.visible = false
	
	game_over.modulate.a = 0
	game_over.visible = true
	
	var tween: Tween = create_tween()
	tween.tween_property(game_over, "modulate", Color.WHITE, 3.0)
	await tween.finished
	
	load_button.visible = true
	quit_button.visible = true
	
	load_button.grab_focus()
	pass

func clear_game_over() -> void:
	load_button.visible = false
	quit_button.visible = false
	await SceneManager.scene_entered
	game_over.visible = false
	
	var player: Player = get_tree().get_first_node_in_group("Player")
	if player:
		player.queue_free()
	pass

func _on_load_pressed() -> void:
	# Call load_game without arguments to match SaveManager API
	SaveManager.load_game()
	clear_game_over()
	pass

func _on_quit_pressed() -> void:
	SceneManager.transition_scene("uid://rkyvut4ndhjv", "", Vector2.ZERO, "up")
	clear_game_over()
	pass

# --- DEBUG MENU TOGGLE ---
func _unhandled_input(event: InputEvent) -> void:
	# Toggle debug menu with DEBUG input action
	if event.is_action_pressed("DEBUG"):
		if Debug_Menu:
			Debug_Menu.visible = not Debug_Menu.visible
			pass
		pass
	pass
