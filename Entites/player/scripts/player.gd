class_name Player
extends CharacterBody2D

# Main player controller.
# Handles movement, state machine, combat, abilities, UI updates, and footsteps.


# SIGNALS

# Emitted when player takes damage.
signal damage_taken


# NODE REFERENCES

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_stand: CollisionShape2D = $CollisionStand
@onready var collision_crouch: CollisionShape2D = $CollisionCrouch
@onready var da_stand: CollisionShape2D = $DamageableArea/DAStand
@onready var da_crouch: CollisionShape2D = $DamageableArea/DACrouch
@onready var one_way_shape_cast: ShapeCast2D = $OneWayShapeCast
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_area: AttackArea = $AttackArea
@onready var damageable_area: DamageableArea = $DamageableArea
@onready var label: Label = $Label
@onready var laser: DarkLaser = $LaserOrigin/DarkLaser
@onready var footstep_player: AudioStreamPlayer2D = %FootstepPlayer


# TUNABLE STATS

@export var walk_speed: float = 80.0
@export var run_speed: float = 240.0
@export var air_velocity: float = 250.0
@export var max_fall_speed: float = 600.0
@export var gravity: float = 980.0
@export var respawn_position: Vector2
@export var afk_threshold_seconds: float = 6.0
@export var movement_lock_time: float = 1.5
@export var double_tap_threshold: float = 0.25


# FOOTSTEPS

@export var ground_tilemap: TileMapLayer
@export var footstep_interval: float = 0.35
@export var footstep_min_speed: float = 5.0

var footstep_timer: float = 0.0

var footstep_sounds := {
	"dirt": [
		preload("uid://bdpyga8tprkb2"),
		preload("uid://b8sv040wd47a")
	]
}


# ABILITIES

# All abilities are always unlocked.
var run: bool = true
var dash: bool = true
var dash_count: int = 0

var double_jump: bool = true
var jump_count: int = 0

var power_up: bool = true
var ground_slam: bool = true
var morph: bool = true

var can_interact: bool = false


# STATE MACHINE

var states: Array[PlayerState] = []
var current_state: PlayerState
var previous_state: PlayerState

var idle: PlayerState
var take_damage: PlayerState
var death: PlayerState

var cast_finished: bool = false


# PLAYER STATS

var _hp: float = 20
var _max_hp: float = 20

# Gets and sets player HP with clamping and UI updates.
var hp: float:
	get: return _hp
	set(value):
		_hp = clampf(value, 0, _max_hp)
		Messages.player_health_changed.emit(_hp, _max_hp)

# Gets and sets max HP safely.
var max_hp: float:
	get: return _max_hp
	set(value):
		_max_hp = maxf(value, 1.0)
		_hp = clampf(_hp, 0, _max_hp)
		Messages.player_health_changed.emit(_hp, _max_hp)


# GENERAL STATE

var direction: Vector2 = Vector2.ZERO
var gravity_multiplier: float = 1.0
var can_move: bool = true
var last_input_time: float = 0.0
var last_tap_time: float = 0.0
var last_tap_dir: float = 0.0
var wants_to_run: bool = false


# INITIAL SETUP

# Initializes player, ensures single instance, and connects systems.
func _ready() -> void:

	add_to_group("Player")

	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 1:
		for p in players:
			if p != self:
				queue_free()
				return

	if get_parent() != get_tree().root:
		call_deferred("reparent", get_tree().root)

	initialize_states()

	if respawn_position == Vector2.ZERO:
		respawn_position = global_position

	Messages.player_healed.connect(_on_player_healed)
	Messages.back_to_title_screen.connect(queue_free)
	Messages.input_hint_changed.connect(_on_input_hint_changed)

	if damageable_area:
		damageable_area.damage_taken.connect(_on_damage_taken)

	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

	if laser:
		laser.player = self
		laser.facing_sign = -1.0 if sprite.flip_h else 1.0
		laser.is_casting = false
		laser.is_channeling = false

	hp = max_hp
	_update_label()


# STATE SETUP

# Initializes all player states and assigns references.
func initialize_states() -> void:

	states.clear()

	for state in $States.get_children():
		if state is PlayerState:
			states.append(state)
			state.player = self

	for state in states:
		if state.name.to_lower() == "idle":
			idle = state
		elif state.name.to_lower() == "takedamage":
			take_damage = state
		elif state is PlayerStateDeath:
			death = state

	change_state(idle)


# STATE SWITCHING

# Changes state and handles transitions.
func change_state(new_state: PlayerState) -> void:

	if new_state == null or new_state == current_state:
		return

	if current_state:
		current_state.exit()

	previous_state = current_state
	current_state = new_state

	current_state.enter()
	_update_label()
	_sync_laser_state()


# UI LABEL

# Updates debug label to show current state.
func _update_label() -> void:

	if label and current_state:
		label.text = str(current_state.name)


# DAMAGE

# Handles incoming damage and triggers appropriate state.
func _on_damage_taken(area: AttackArea) -> void:

	hp -= area.damage
	damage_taken.emit()

	if hp <= 0 and death:
		change_state(death)

	elif take_damage:
		var dir = -1.0 if area.global_position.x > global_position.x else 1.0
		take_damage.dir = dir
		change_state(take_damage)

# LASER

# Updates the laser position and facing direction.
func _update_laser_transform() -> void:
	if not laser:
		return

	laser.global_position = $LaserOrigin.global_position
	laser.player = self
	laser.facing_sign = -1.0 if sprite.flip_h else 1.0


# Updates laser casting state.
func _sync_laser_state() -> void:
	if not laser:
		return

	var casting := current_state is PlayerStateCast
	laser.is_casting = casting
	laser.is_channeling = casting

# HEALING

# Adds health when healed.
func _on_player_healed(amount: float) -> void:
	hp += amount


# INTERACTION

# Updates interaction availability.
func _on_input_hint_changed(prompt_name: String) -> void:
	can_interact = (prompt_name == "interact")

# ANIMATION

# Tracks when the cast animation finishes.
func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Cast":
		cast_finished = true

# DEATH / RESPAWN

# Resets player to respawn state.
func die(reason: String = "unknown") -> void:

	global_position = respawn_position
	velocity = Vector2.ZERO
	direction = Vector2.ZERO
	wants_to_run = false
	cast_finished = false
	can_move = true

	if laser:
		laser.is_casting = false
		laser.is_channeling = false

	change_state(idle)
