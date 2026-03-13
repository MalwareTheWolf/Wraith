extends CanvasLayer
# Title screen with Play menu, New/Load game menus, heartbeat, and loading integration

# --- Nodes ---
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

# --- Heartbeat lock ---
var heartbeat_locked: bool = false

func _ready() -> void:
	# Connect buttons
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

	# Start with Play menu visible
	show_play_menu()

	# Heartbeat hover setup
	_connect_heartbeat_hover()

	# Start idle heartbeat
	Audio.play_heartbeat_loop(0)

	# Animation callback
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)


# --- Show menus ---
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
	Audio.play_heartbeat_loop(0)

func _on_play_pressed() -> void:
	if main_menu:
		main_menu.visible = true
	if play_menu:
		play_menu.visible = false
	if new_game_button:
		new_game_button.grab_focus()
	Audio.play_heartbeat_loop(1)


func show_new_game_menu() -> void:
	if main_menu:
		main_menu.visible = false
	if new_game_menu:
		new_game_menu.visible = true
	if load_game_menu:
		load_game_menu.visible = false
	Audio.play_heartbeat_loop(2)

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
	Audio.play_heartbeat_loop(2)

	if load_slot_01:
		load_slot_01.grab_focus()
	load_slot_01.disabled = not SaveManager.save_file_exists(0)
	load_slot_02.disabled = not SaveManager.save_file_exists(1)
	load_slot_03.disabled = not SaveManager.save_file_exists(2)


# --- Button pressed callbacks ---
func _on_new_game_pressed(slot: int) -> void:
	_start_game(slot, true)

func _on_load_game_pressed(slot: int) -> void:
	_start_game(slot, false)

func _start_game(slot: int, is_new: bool) -> void:
	# Lock heartbeat and stop immediately
	heartbeat_locked = true
	Audio.stop_heartbeat()
	Audio.play_ui_audio(Audio.ui_select_audio)

	# Hide all menus
	if play_menu:
		play_menu.visible = false
	if main_menu:
		main_menu.visible = false
	if new_game_menu:
		new_game_menu.visible = false
	if load_game_menu:
		load_game_menu.visible = false

	# Start loading scene
	var loading_scene = preload("uid://cxdv6nibhjnju").instantiate()
	get_tree().root.add_child(loading_scene)
	loading_scene._start(slot, is_new)


# --- Heartbeat hover connections ---
func _connect_heartbeat_hover() -> void:
	var stage1 := [play_button, new_game_button, load_game_button]
	var stage2 := [new_slot_01, new_slot_02, new_slot_03, load_slot_01, load_slot_02, load_slot_03]

	for btn in stage1:
		if btn:
			btn.mouse_entered.connect(func() -> void:
				if not heartbeat_locked:
					Audio.play_heartbeat_loop(1))
			btn.mouse_exited.connect(func() -> void:
				if not heartbeat_locked:
					Audio.play_heartbeat_loop(0))

	for btn in stage2:
		if btn:
			btn.mouse_entered.connect(func() -> void:
				if not heartbeat_locked:
					Audio.play_heartbeat_loop(2))
			btn.mouse_exited.connect(func() -> void:
				if not heartbeat_locked:
					Audio.play_heartbeat_loop(1))


# --- Back button ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if play_menu and not play_menu.visible:
			show_play_menu()


# --- Animation finished ---
func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "start" and animation_player:
		animation_player.play("loop")
