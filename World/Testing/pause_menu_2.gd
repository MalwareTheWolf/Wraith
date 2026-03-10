class_name PauseMenuTest
extends CanvasLayer

#region /// ONREADY VARIABLES
@onready var main_node: Control = $MainNode
@onready var book: AnimatedSprite2D = $MainNode/Book
@onready var animation_player: AnimationPlayer = $MainNode/AnimationPlayer

@onready var tabs: Control = $MainNode/Tabs
@onready var pages: Control = $MainNode/Pages

@onready var map_button: BaseButton = $MainNode/Tabs/Map/MapButton
@onready var player_button: BaseButton = $MainNode/Tabs/PlayerStats/PlayerStatsButton
@onready var system_button: BaseButton = $MainNode/Tabs/System/SystemButton
@onready var spells_button: BaseButton = $MainNode/Tabs/Spells/SpellsButton
@onready var inventory_button: BaseButton = $MainNode/Tabs/Inventory/InventoryButton

@onready var map_page: Control = $MainNode/Pages/Map
@onready var player_page: Control = $MainNode/Pages/Player
@onready var system_page: Control = $MainNode/Pages/System
@onready var spells_page: Control = $MainNode/Pages/Spells
@onready var inventory_page: Control = $MainNode/Pages/Inventory
#endregion

#region /// STANDARD VARIABLES
var current_page: String = "Player"
var is_open: bool = false
var is_turning_page: bool = false
#endregion

func _ready() -> void:
	# Force UI to process while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	main_node.process_mode = Node.PROCESS_MODE_ALWAYS

	# Pause the game here
	get_tree().paused = true

	# Hide pages & disable buttons initially
	hide_all_pages()
	set_tab_buttons_enabled(false)

	# Connect button signals
	map_button.pressed.connect(_on_map_pressed)
	player_button.pressed.connect(_on_player_pressed)
	system_button.pressed.connect(_on_system_pressed)
	spells_button.pressed.connect(_on_spells_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)

	# Play opening animations
	if book.sprite_frames and book.sprite_frames.has_animation("open"):
		book.play("open")
		await book.animation_finished

	if book.sprite_frames and book.sprite_frames.has_animation("tabs_appear"):
		book.play("tabs_appear")
		await book.animation_finished

	book.visible = false

	# Show default page
	is_open = true
	show_page("Player")
	set_tab_buttons_enabled(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		close_pause_menu()

# --- PAGE CONTROL ---
func hide_all_pages() -> void:
	map_page.visible = false
	player_page.visible = false
	system_page.visible = false
	spells_page.visible = false
	inventory_page.visible = false

func show_page(page_name: String) -> void:
	hide_all_pages()
	match page_name:
		"Map":
			map_page.visible = true
		"Player":
			player_page.visible = true
		"System":
			system_page.visible = true
		"Spells":
			spells_page.visible = true
		"Inventory":
			inventory_page.visible = true
	current_page = page_name

# --- BUTTON STATE ---
func set_tab_buttons_enabled(value: bool) -> void:
	map_button.disabled = !value
	player_button.disabled = !value
	system_button.disabled = !value
	spells_button.disabled = !value
	inventory_button.disabled = !value

# --- PAGE TURNING ---
func turn_page(new_page: String) -> void:
	if !is_open or is_turning_page or new_page == current_page:
		return

	is_turning_page = true
	set_tab_buttons_enabled(false)
	hide_all_pages()
	book.visible = true

	if should_flip_left(current_page, new_page):
		if book.sprite_frames.has_animation("flip_left_3"):
			book.play("flip_left_3")
			await book.animation_finished
	else:
		if book.sprite_frames.has_animation("flip_right_2"):
			book.play("flip_right_2")
			await book.animation_finished

	book.visible = false
	show_page(new_page)
	set_tab_buttons_enabled(true)
	is_turning_page = false

func should_flip_left(from_page: String, to_page: String) -> bool:
	var order: Array[String] = ["Player","Map","Spells","Inventory","System"]
	return order.find(to_page) < order.find(from_page)

# --- CLOSE MENU ---
func close_pause_menu() -> void:
	if !is_open or is_turning_page:
		return

	set_tab_buttons_enabled(false)
	hide_all_pages()
	book.visible = true

	if book.sprite_frames.has_animation("tabs_disappear"):
		book.play("tabs_disappear")
		await book.animation_finished

	if book.sprite_frames.has_animation("close"):
		book.play("close")
		await book.animation_finished

	get_tree().paused = false
	queue_free()

# --- BUTTON CALLBACKS ---
func _on_map_pressed():
	turn_page("Map")
func _on_player_pressed():
	turn_page("Player")
func _on_system_pressed():
	turn_page("System")
func _on_spells_pressed():
	turn_page("Spells")
func _on_inventory_pressed():
	turn_page("Inventory")
