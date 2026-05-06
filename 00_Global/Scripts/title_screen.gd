extends CanvasLayer

const MENU_MUSIC: AudioStream = preload("uid://4o1ya1eaqxig")

@onready var play_menu: VBoxContainer = get_node_or_null("Control/PlayMenu")
@onready var play_button: Button = get_node_or_null("Control/PlayMenu/PlayButton")

@onready var main_menu: VBoxContainer = $Control/MainMenu
@onready var new_game_menu: VBoxContainer = $Control/NewGameMenu
@onready var load_game_menu: VBoxContainer = $Control/LoadGameMenu

@onready var new_game_button: Button = $Control/MainMenu/NewGameButton
@onready var load_game_button: Button = $Control/MainMenu/LoadGameButton

@onready var new_slot_01: Button = $Control/NewGameMenu/NewSlot01
@onready var new_slot_02: Button = $Control/NewGameMenu/NewSlot02
@onready var new_slot_03: Button = $Control/NewGameMenu/NewSlot03

@onready var load_slot_01: Button = $Control/LoadGameMenu/LoadSlot01
@onready var load_slot_02: Button = $Control/LoadGameMenu/LoadSlot02
@onready var load_slot_03: Button = $Control/LoadGameMenu/LoadSlot03

@onready var animation_player: AnimationPlayer = get_node_or_null("Control/MainMenu/Logo/AnimationPlayer")


func _ready() -> void:
	Audio.play_music(MENU_MUSIC)
	Audio.setup_button_audio(self)

	if play_button:
		play_button.pressed.connect(_on_play_pressed)

	if new_game_button:
		new_game_button.pressed.connect(show_new_game_menu)

	if load_game_button:
		load_game_button.pressed.connect(show_load_game_menu)

	if new_slot_01:
		new_slot_01.pressed.connect(_on_new_game_pressed.bind(0))

	if new_slot_02:
		new_slot_02.pressed.connect(_on_new_game_pressed.bind(1))

	if new_slot_03:
		new_slot_03.pressed.connect(_on_new_game_pressed.bind(2))

	if load_slot_01:
		load_slot_01.pressed.connect(_on_load_game_pressed.bind(0))

	if load_slot_02:
		load_slot_02.pressed.connect(_on_load_game_pressed.bind(1))

	if load_slot_03:
		load_slot_03.pressed.connect(_on_load_game_pressed.bind(2))

	show_play_menu()

	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)


func show_play_menu() -> void:
	if play_menu:
		play_menu.visible = true

	if main_menu:
		main_menu.visible = false

	if new_game_menu:
		new_game_menu.visible = false

	if load_game_menu:
		load_game_menu.visible = false

	if play_button:
		play_button.grab_focus()


func _on_play_pressed() -> void:
	if main_menu:
		main_menu.visible = true

	if play_menu:
		play_menu.visible = false

	if new_game_button:
		new_game_button.grab_focus()


func show_new_game_menu() -> void:
	if main_menu:
		main_menu.visible = false

	if new_game_menu:
		new_game_menu.visible = true

	if load_game_menu:
		load_game_menu.visible = false

	if new_slot_01:
		new_slot_01.grab_focus()

	if SaveManager.save_file_exists(0) and new_slot_01:
		new_slot_01.text = "Replace Slot 01"

	if SaveManager.save_file_exists(1) and new_slot_02:
		new_slot_02.text = "Replace Slot 02"

	if SaveManager.save_file_exists(2) and new_slot_03:
		new_slot_03.text = "Replace Slot 03"


func show_load_game_menu() -> void:
	if main_menu:
		main_menu.visible = false

	if new_game_menu:
		new_game_menu.visible = false

	if load_game_menu:
		load_game_menu.visible = true

	if load_slot_01:
		load_slot_01.grab_focus()

	if load_slot_01:
		load_slot_01.disabled = not SaveManager.save_file_exists(0)

	if load_slot_02:
		load_slot_02.disabled = not SaveManager.save_file_exists(1)

	if load_slot_03:
		load_slot_03.disabled = not SaveManager.save_file_exists(2)


func _on_new_game_pressed(slot: int) -> void:
	_start_game(slot, true)


func _on_load_game_pressed(slot: int) -> void:
	_start_game(slot, false)


func _start_game(slot: int, is_new: bool) -> void:
	# No extra/static sound here.
	# The button click sound already plays from Audio.setup_button_audio().

	if play_menu:
		play_menu.visible = false

	if main_menu:
		main_menu.visible = false

	if new_game_menu:
		new_game_menu.visible = false

	if load_game_menu:
		load_game_menu.visible = false

	var loading_scene = preload("uid://cxdv6nibhjnju").instantiate()
	get_tree().root.add_child(loading_scene)
	loading_scene._start(slot, is_new)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if play_menu and not play_menu.visible:
			show_play_menu()


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "start" and animation_player:
		animation_player.play("loop")
