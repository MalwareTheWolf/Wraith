extends Control

# Debug menu controller.
# Handles toggles, cheats, and live debugging info.


# NODE REFERENCES
@onready var debug_label: Label = $Label
@onready var infinite_health_button: BaseButton = $VBoxContainer/Infinite_Health
@onready var unlock_ability_button: BaseButton = $VBoxContainer/Unlock_Ability
@onready var particles_button: BaseButton = $VBoxContainer/Particles
@onready var kill_player_button: BaseButton = $VBoxContainer/GameOver


# RUNTIME
var player: Player
var infinite_health: bool = false

var ability_list: Array[String] = [
	"run",
	"dash",
	"double_jump",
	"lightning",
	"Chain_lightning",
	"dark_blast",
	"heavy_attack",
	"power_up",
	"ground_slam",
	"morph"
]

var current_ability_index: int = 0


# LIFECYCLE
func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

	if infinite_health_button:
		infinite_health_button.pressed.connect(_on_infinite_health_pressed)

	if unlock_ability_button:
		unlock_ability_button.pressed.connect(_on_unlock_ability_pressed)

	if particles_button:
		particles_button.pressed.connect(_on_particles_pressed)

	if kill_player_button:
		kill_player_button.pressed.connect(_on_kill_player_pressed)

	update_unlock_ability_button()
	visible = false


# PROCESS
func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		update_unlock_ability_button()
		return

	if infinite_health:
		player.hp = player.max_hp

	_update_debug_label()


# INPUT
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_right"):
		next_ability()

	elif event.is_action_pressed("ui_left"):
		previous_ability()


# DEBUG DISPLAY
func _update_debug_label() -> void:
	if not debug_label or player == null:
		return

	debug_label.text = """
STATE: %s
HP: %.1f / %.1f
DASH: %s
DASH COUNT: %d
CAN DASH: %s
ON FLOOR: %s
VELOCITY: %s
ABILITY: %s
""" % [
		player.current_state.name,
		player.hp,
		player.max_hp,
		player.dash,
		player.dash_count,
		player.can_dash(),
		player.is_on_floor(),
		player.velocity,
		format_ability_name(ability_list[current_ability_index])
	]


# BUTTON TEXT
func update_unlock_ability_button() -> void:
	if unlock_ability_button == null:
		return

	if player == null:
		unlock_ability_button.text = "Unlock Ability"
		return

	var ability_name: String = ability_list[current_ability_index]
	var display_name: String = format_ability_name(ability_name)

	if bool(player.get(ability_name)):
		unlock_ability_button.text = display_name + " (Unlocked)"
	else:
		unlock_ability_button.text = "Unlock " + display_name


func next_ability() -> void:
	current_ability_index = (current_ability_index + 1) % ability_list.size()
	update_unlock_ability_button()


func previous_ability() -> void:
	current_ability_index = (current_ability_index - 1 + ability_list.size()) % ability_list.size()
	update_unlock_ability_button()


func format_ability_name(ability_name: String) -> String:
	var parts: PackedStringArray = ability_name.split("_")
	for i: int in range(parts.size()):
		parts[i] = parts[i].capitalize()
	return " ".join(parts)


# DEBUG ACTIONS
func _on_infinite_health_pressed() -> void:
	infinite_health = !infinite_health
	print("Infinite Health:", infinite_health)


func _on_unlock_ability_pressed() -> void:
	if player == null:
		return

	var ability_name: String = ability_list[current_ability_index]
	player.set(ability_name, true)

	update_unlock_ability_button()
	print(format_ability_name(ability_name), " unlocked")


func _on_particles_pressed() -> void:
	if player == null:
		return

	VisualEffects.jump_dust(player.global_position)
	VisualEffects.land_dust(player.global_position)
	VisualEffects.hit_dust(player.global_position)

	print("Spawned test particles")


func _on_kill_player_pressed() -> void:
	if player == null:
		return

	player.hp = 0

	if player.death:
		player.change_state(player.death)

	print("Player killed (debug)")
