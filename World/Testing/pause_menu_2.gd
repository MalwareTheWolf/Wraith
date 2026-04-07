class_name PauseMenuBook
extends CanvasLayer

# Main UI references.
@onready var main_node: Control = $MainNode
@onready var book: AnimatedSprite2D = $MainNode/Book
@onready var pages: Control = $MainNode/Pages
@onready var tabs: Control = $MainNode/Tabs

# Main pages.
@onready var map_page: MapPage = $MainNode/Pages/Map
@onready var player_page: Control = $MainNode/Pages/Player
@onready var system_page: Control = $MainNode/Pages/System
@onready var spells_page: Control = $MainNode/Pages/Spells
@onready var inventory_page: Control = $MainNode/Pages/Inventory
@onready var load_quit_page: Control = $MainNode/Pages/Load_Quit   # ✅ NEW

# System tabs.
@onready var system_tabs: TabContainer = $MainNode/Pages/System/TabContainer

# System section buttons.
@onready var audio_button: BaseButton = $MainNode/Pages/System/Settings_Sections/Audio_Button
@onready var video_button: BaseButton = $MainNode/Pages/System/Settings_Sections/Video_Button
@onready var graphics_button: BaseButton = $MainNode/Pages/System/Settings_Sections/Graphics_Button
@onready var controls_button: BaseButton = $MainNode/Pages/System/Settings_Sections/Controls_Button

# Load / Quit buttons.
@onready var load_last_save_button: Button = $MainNode/Pages/Load_Quit/LoadLastSave
@onready var quit_to_menu_button: Button = $MainNode/Pages/Load_Quit/QuitToMenu

# Main tab buttons.
@onready var map_button: BaseButton = $MainNode/Tabs/Map/MapButton
@onready var player_button: BaseButton = $MainNode/Tabs/PlayerStats/PlayerStatsButton
@onready var system_button: BaseButton = $MainNode/Tabs/System/SystemButton
@onready var spells_button: BaseButton = $MainNode/Tabs/Spells/SpellsButton
@onready var inventory_button: BaseButton = $MainNode/Tabs/Inventory/InventoryButton
@onready var load_quit_button: BaseButton = $MainNode/Tabs/LoadQuit/LoadQuitButton   # ✅ NEW

# Current menu state.
var current_page: String = "Player"
var is_open: bool = false
var is_turning_page: bool = false
var is_closing: bool = false
var is_action_locked: bool = false



#LIFECYCLE

func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS
	main_node.process_mode = Node.PROCESS_MODE_ALWAYS
	pages.process_mode = Node.PROCESS_MODE_ALWAYS
	tabs.process_mode = Node.PROCESS_MODE_ALWAYS
	book.process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().paused = true

	pages.visible = false
	tabs.visible = false
	book.visible = true

	hide_all_pages()
	set_tab_buttons_enabled(false)
	connect_buttons()

	await play_open_sequence()



#INPUT

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close_pause_menu()



#CONNECTIONS

func connect_buttons() -> void:

	if map_button:
		map_button.pressed.connect(_on_map_pressed)

	if player_button:
		player_button.pressed.connect(_on_player_pressed)

	if system_button:
		system_button.pressed.connect(_on_system_pressed)

	if spells_button:
		spells_button.pressed.connect(_on_spells_pressed)

	if inventory_button:
		inventory_button.pressed.connect(_on_inventory_pressed)

	if load_quit_button:
		load_quit_button.pressed.connect(_on_load_quit_pressed)   # ✅ NEW

	if audio_button:
		audio_button.pressed.connect(_on_audio_pressed)

	if video_button:
		video_button.pressed.connect(_on_video_pressed)

	if graphics_button:
		graphics_button.pressed.connect(_on_graphics_pressed)

	if controls_button:
		controls_button.pressed.connect(_on_controls_pressed)

	if load_last_save_button:
		load_last_save_button.pressed.connect(_on_load_last_save_pressed)

	if quit_to_menu_button:
		quit_to_menu_button.pressed.connect(_on_quit_to_menu_pressed)



#OPEN / CLOSE

func play_open_sequence() -> void:

	if book.sprite_frames and book.sprite_frames.has_animation("open"):
		book.play("open")
		await book.animation_finished

	if book.sprite_frames and book.sprite_frames.has_animation("tabs_appear"):
		book.play("tabs_appear")
		await book.animation_finished

	book.visible = false
	pages.visible = true
	tabs.visible = true

	is_open = true
	show_page("Player")
	set_tab_buttons_enabled(true)

func close_pause_menu() -> void:

	if not is_open or is_turning_page or is_closing:
		return

	is_closing = true
	set_tab_buttons_enabled(false)

	pages.visible = false
	tabs.visible = false
	book.visible = true

	if book.sprite_frames and book.sprite_frames.has_animation("tabs_disappear"):
		book.play("tabs_disappear")
		await book.animation_finished

	if book.sprite_frames and book.sprite_frames.has_animation("close"):
		book.play("close")
		await book.animation_finished

	get_tree().paused = false
	queue_free()



#PAGE CONTROL

func hide_all_pages() -> void:
	for page in pages.get_children():
		page.visible = false

func show_page(page_name: String) -> void:

	hide_all_pages()

	match page_name:
		"Map":
			map_page.visible = true
			map_page.refresh_page()

		"Player":
			player_page.visible = true

		"System":
			system_page.visible = true
			if system_tabs:
				system_tabs.current_tab = 0

		"Spells":
			spells_page.visible = true

		"Inventory":
			inventory_page.visible = true

		"Load_Quit":   # ✅ NEW
			load_quit_page.visible = true

	current_page = page_name

func set_tab_buttons_enabled(value: bool) -> void:

	if map_button:
		map_button.disabled = not value
	if player_button:
		player_button.disabled = not value
	if system_button:
		system_button.disabled = not value
	if spells_button:
		spells_button.disabled = not value
	if inventory_button:
		inventory_button.disabled = not value
	if load_quit_button:
		load_quit_button.disabled = not value   # ✅ NEW



#PAGE TURNING

func turn_page(new_page: String) -> void:

	if not is_open or is_turning_page or is_action_locked or new_page == current_page:
		return

	is_turning_page = true
	set_tab_buttons_enabled(false)

	pages.visible = false
	tabs.visible = false
	book.visible = true

	if should_flip_left(current_page, new_page):
		if book.sprite_frames and book.sprite_frames.has_animation("flip_left_3"):
			book.play("flip_left_3")
			await book.animation_finished
	else:
		if book.sprite_frames and book.sprite_frames.has_animation("flip_right_2"):
			book.play("flip_right_2")
			await book.animation_finished

	book.visible = false
	pages.visible = true
	tabs.visible = true

	show_page(new_page)
	set_tab_buttons_enabled(true)
	is_turning_page = false

func should_flip_left(from_page: String, to_page: String) -> bool:
	var order: Array[String] = ["Player", "Map", "Spells", "Inventory", "System", "Load_Quit"]
	return order.find(to_page) < order.find(from_page)



#TAB CALLBACKS

func _on_map_pressed() -> void:
	turn_page("Map")

func _on_player_pressed() -> void:
	turn_page("Player")

func _on_system_pressed() -> void:
	turn_page("System")

func _on_spells_pressed() -> void:
	turn_page("Spells")

func _on_inventory_pressed() -> void:
	turn_page("Inventory")

func _on_load_quit_pressed() -> void:   # ✅ NEW
	turn_page("Load_Quit")



#SYSTEM SUBPAGE CALLBACKS

func _on_audio_pressed() -> void:
	if system_tabs:
		system_tabs.current_tab = 0

func _on_video_pressed() -> void:
	if system_tabs:
		system_tabs.current_tab = 1

func _on_graphics_pressed() -> void:
	if system_tabs:
		system_tabs.current_tab = 2

func _on_controls_pressed() -> void:
	if system_tabs:
		system_tabs.current_tab = 3



#LOAD LAST SAVE

func _on_load_last_save_pressed() -> void:

	if is_turning_page or is_action_locked:
		return

	is_action_locked = true
	set_tab_buttons_enabled(false)

	if load_last_save_button:
		load_last_save_button.disabled = true
	if quit_to_menu_button:
		quit_to_menu_button.disabled = true

	get_tree().paused = false

	await SaveManager.load_game()

	queue_free()
	pass



#QUIT TO MENU

func _on_quit_to_menu_pressed() -> void:

	if is_turning_page or is_action_locked:
		return

	is_action_locked = true
	set_tab_buttons_enabled(false)

	if load_last_save_button:
		load_last_save_button.disabled = true
	if quit_to_menu_button:
		quit_to_menu_button.disabled = true

	get_tree().paused = false

	await SceneManager.transition_scene("uid://rkyvut4ndhjv", "", Vector2.ZERO, "up")

	queue_free()
	pass
