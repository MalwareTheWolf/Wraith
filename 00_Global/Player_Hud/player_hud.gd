# PlayerHud.gd
extends CanvasLayer

@onready var hp_margin_container: MarginContainer = %HPMarginContainer
@onready var hp_bar: TextureProgressBar = %HPBar

@onready var game_over: Control = %GameOver
@onready var load_button: Button = %LoadButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	# Connect health update signal
	Messages.player_health_changed.connect(update_health_bar)
	
	# Setup game over UI
	game_over.visible = false
	load_button.pressed.connect(_on_load_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func update_health_bar(hp: float, max_hp: float) -> void:
	var value: float = (hp / max_hp) * 100
	hp_bar.value = value
	hp_margin_container.size.x = max_hp + 22


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


func clear_game_over() -> void:
	load_button.visible = false
	quit_button.visible = false
	await SceneManager.scene_entered
	game_over.visible = false
	
	var player: Player = get_tree().get_first_node_in_group("Player")
	if player:
		player.queue_free()


func _on_load_pressed() -> void:
	# Call load_game without arguments to match SaveManager API
	SaveManager.load_game()
	clear_game_over()


func _on_quit_pressed() -> void:
	SceneManager.transition_scene("uid://rkyvut4ndhjv", "", Vector2.ZERO, "up")
	clear_game_over()
