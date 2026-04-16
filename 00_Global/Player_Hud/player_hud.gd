extends CanvasLayer

#region --- ONREADY VARIABLES
@onready var hp_margin_container: MarginContainer = %HPMarginContainer
@onready var hp_bar: TextureProgressBar = %HPBar

@onready var game_over: Control = %GameOver
@onready var load_button: Button = %LoadButton
@onready var quit_button: Button = %QuitButton

@onready var debug_menu: Control = $Debug_Menu

@onready var win_panel: Control = $WIN
@onready var win_quit_button: Button = $WIN/QuitButton2
#endregion

var win_showing: bool = false


func _ready() -> void:
	if debug_menu:
		debug_menu.visible = false

	Messages.player_health_changed.connect(update_health_bar)
	Messages.win_triggered.connect(show_win)

	game_over.visible = false
	load_button.pressed.connect(_on_load_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	win_panel.visible = false
	win_panel.modulate.a = 0.0

	if win_quit_button:
		win_quit_button.pressed.connect(_on_win_quit_pressed)


func update_health_bar(hp: float, max_hp: float) -> void:
	var value: float = (hp / max_hp) * 100.0
	hp_bar.value = value
	hp_margin_container.size.x = max_hp + 22


func show_game_over() -> void:
	load_button.visible = false
	quit_button.visible = false

	game_over.modulate.a = 0.0
	game_over.visible = true

	var tween: Tween = create_tween()
	tween.tween_property(game_over, "modulate", Color.WHITE, 3.0)
	await tween.finished

	load_button.visible = true
	quit_button.visible = true
	load_button.grab_focus()


func show_win() -> void:
	if win_showing:
		return

	win_showing = true

	win_panel.visible = true
	win_panel.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(win_panel, "modulate", Color.WHITE, 2.0)
	await tween.finished

	if win_quit_button:
		win_quit_button.grab_focus()


func hide_win() -> void:
	win_showing = false
	win_panel.visible = false
	win_panel.modulate.a = 0.0


func clear_game_over() -> void:
	load_button.visible = false
	quit_button.visible = false
	await SceneManager.scene_entered
	game_over.visible = false

	var player: Player = get_tree().get_first_node_in_group("Player")
	if player:
		player.queue_free()


func _on_load_pressed() -> void:
	SaveManager.load_game()
	clear_game_over()


func _on_quit_pressed() -> void:
	SceneManager.transition_scene("uid://rkyvut4ndhjv", "", Vector2.ZERO, "up")
	clear_game_over()


func _on_win_quit_pressed() -> void:
	print("WIN QUIT PRESSED")
	SceneManager.transition_scene("uid://rkyvut4ndhjv", "", Vector2.ZERO, "up")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("DEBUG"):
		if debug_menu:
			debug_menu.visible = not debug_menu.visible
