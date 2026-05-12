extends CanvasLayer

#PLAYER HUD
#Handles:
# - Health bar display
# - Game over screen
# - Win screen
# - Load and quit buttons


#NODE REFERENCES

@onready var hp_margin_container: MarginContainer = %HPMarginContainer
@onready var hp_bar: TextureProgressBar = %HPBar

@onready var game_over: Control = %GameOver
@onready var load_button: Button = %LoadButton
@onready var quit_button: Button = %QuitButton

@onready var win_panel: Control = $WIN
@onready var win_quit_button: Button = $WIN/QuitButton2


#RUNTIME STATE

var win_showing: bool = false
var game_over_showing: bool = false


#READY

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if game_over:
		game_over.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	if load_button:
		load_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	if quit_button:
		quit_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	if win_panel:
		win_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	if win_quit_button:
		win_quit_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	Messages.player_health_changed.connect(update_health_bar)
	Messages.win_triggered.connect(show_win)

	game_over.visible = false
	load_button.visible = false
	quit_button.visible = false

	load_button.pressed.connect(_on_load_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	win_panel.visible = false
	win_panel.modulate.a = 0.0

	if win_quit_button:
		win_quit_button.pressed.connect(_on_win_quit_pressed)


#HEALTH BAR

func update_health_bar(hp: float, max_hp: float) -> void:
	var value: float = (hp / max_hp) * 100.0

	hp_bar.value = value
	hp_margin_container.size.x = max_hp + 22


#GAME OVER

func show_game_over() -> void:
	if game_over_showing:
		return

	game_over_showing = true
	win_showing = false

	get_tree().paused = true

	load_button.visible = false
	quit_button.visible = false

	game_over.modulate.a = 0.0
	game_over.visible = true

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(
		game_over,
		"modulate",
		Color.WHITE,
		3.0
	)

	await tween.finished

	load_button.visible = true
	quit_button.visible = true
	load_button.grab_focus()


func clear_game_over() -> void:
	game_over_showing = false

	load_button.visible = false
	quit_button.visible = false

	game_over.visible = false
	game_over.modulate = Color.WHITE

	get_tree().paused = false

	await SceneManager.scene_entered

	var player: Player = get_tree().get_first_node_in_group("Player")

	if player:
		player.queue_free()


#WIN SCREEN

func show_win() -> void:
	if win_showing:
		return

	win_showing = true
	game_over_showing = false

	get_tree().paused = true

	win_panel.visible = true
	win_panel.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(
		win_panel,
		"modulate",
		Color.WHITE,
		2.0
	)

	await tween.finished

	if win_quit_button:
		win_quit_button.grab_focus()


func hide_win() -> void:
	win_showing = false

	win_panel.visible = false
	win_panel.modulate.a = 0.0


func clear_win() -> void:
	win_showing = false

	win_panel.visible = false
	win_panel.modulate.a = 0.0

	get_tree().paused = false


#BUTTONS

func _on_load_pressed() -> void:
	get_tree().paused = false

	SaveManager.load_game()

	clear_game_over()


func _on_quit_pressed() -> void:
	get_tree().paused = false

	SceneManager.transition_scene(
		"uid://rkyvut4ndhjv",
		"",
		Vector2.ZERO,
		"up"
	)

	clear_game_over()


func _on_win_quit_pressed() -> void:
	clear_win()

	SceneManager.transition_scene(
		"uid://rkyvut4ndhjv",
		"",
		Vector2.ZERO,
		"up"
	)
