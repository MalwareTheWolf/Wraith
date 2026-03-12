extends CanvasLayer
# Title Screen logic with Play button, heartbeat, menu navigation, and save/load handling

#region On ready variables
@onready var play_menu: VBoxContainer = $Control/PlayMenu
@onready var play_button: Button = $Control/PlayMenu/PlayButton

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
#endregion

func _ready() -> void:
	# Show Play menu first
	show_play_menu()

	# Connect Play button
	if play_button:
		play_button.pressed.connect(_on_play_pressed)

	# Connect New/Load buttons
	if new_game_button:
		new_game_button.pressed.connect(show_new_game_menu)
	if load_game_button:
		load_game_button.pressed.connect(show_load_game_menu)

	# Connect slots
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

	# Heartbeat hover setup
	_connect_heartbeat_hover()

	# Start default heartbeat
	Audio.play_heartbeat_loop(0)

	# Animation callback
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
	pass

# Heartbeat hover helpers
func _connect_heartbeat_hover() -> void:
	var stage1 := [play_button, new_game_button, load_game_button]
	var stage2 := [new_slot_01, new_slot_02, new_slot_03, load_slot_01, load_slot_02, load_slot_03]

	for btn in stage1:
		if btn:
			btn.mouse_entered.connect(func() -> void: Audio.play_heartbeat_loop(1))
			btn.mouse_exited.connect(func() -> void: Audio.play_heartbeat_loop(0))

	for btn in stage2:
		if btn:
			btn.mouse_entered.connect(func() -> void: Audio.play_heartbeat_loop(2))
			btn.mouse_exited.connect(func() -> void: Audio.play_heartbeat_loop(1))

# Unhandled input (back button)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if play_menu and play_menu.visible:
			return
		if main_menu and not main_menu.visible:
			show_main_menu()
	pass

# --- Menu navigation ---
func show_play_menu() -> void:
	play_menu.visible = true
	main_menu.visible = false
	new_game_menu.visible = false
	load_game_menu.visible = false
	if play_button:
		play_button.grab_focus()
	Audio.play_heartbeat_loop(0)
	pass

func _on_play_pressed() -> void:
	# Hide Play menu and show New/Load Game buttons
	play_menu.visible = false
	show_main_menu()
	Audio.play_ui_audio(Audio.ui_select_audio)
	pass

func show_main_menu() -> void:
	main_menu.visible = true
	new_game_menu.visible = false
	load_game_menu.visible = false
	if new_game_button:
		new_game_button.grab_focus()
	Audio.play_heartbeat_loop(0)
	pass

func show_new_game_menu() -> void:
	main_menu.visible = false
	new_game_menu.visible = true
	load_game_menu.visible = false

	# Heartbeat for slots
	Audio.play_heartbeat_loop(2)

	if new_slot_01:
		new_slot_01.grab_focus()

	if SaveManager.save_file_exists(0) and new_slot_01:
		new_slot_01.text = "Replace Slot 01"
	if SaveManager.save_file_exists(1) and new_slot_02:
		new_slot_02.text = "Replace Slot 02"
	if SaveManager.save_file_exists(2) and new_slot_03:
		new_slot_03.text = "Replace Slot 03"
	pass

func show_load_game_menu() -> void:
	main_menu.visible = false
	new_game_menu.visible = false
	load_game_menu.visible = true

	# Heartbeat for slots
	Audio.play_heartbeat_loop(2)

	if load_slot_01:
		load_slot_01.grab_focus()

	load_slot_01.disabled = not SaveManager.save_file_exists(0)
	load_slot_02.disabled = not SaveManager.save_file_exists(1)
	load_slot_03.disabled = not SaveManager.save_file_exists(2)
	pass

# --- Button pressed callbacks ---
func _on_new_game_pressed(slot: int) -> void:
	Audio.stop_heartbeat()
	Audio.play_ui_audio(Audio.ui_select_audio)

	main_menu.visible = false
	new_game_menu.visible = false
	load_game_menu.visible = false

	var loading_scene = preload("res://Loading.tscn").instantiate()
	get_tree().root.add_child(loading_scene)
	loading_scene._start(slot, true) # true = new game
	pass

func _on_load_game_pressed(slot: int) -> void:
	Audio.stop_heartbeat()
	Audio.play_ui_audio(Audio.ui_select_audio)

	main_menu.visible = false
	new_game_menu.visible = false
	load_game_menu.visible = false

	var loading_scene = preload("res://Loading.tscn").instantiate()
	get_tree().root.add_child(loading_scene)
	loading_scene._start(slot, false) # false = load game
	pass

# Animation finished
func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "start" and animation_player:
		animation_player.play("loop")
	pass
