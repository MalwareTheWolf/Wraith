class_name Player
extends CharacterBody2D

# Main player controller.
# Handles movement, state machine, combat, abilities, and UI updates.


#SIGNALS

# Emitted when player takes damage.
signal damage_taken



#NODE REFERENCES

@onready var sprite: Sprite2D = $Sprite2D
# Main player sprite.
@onready var collision_stand: CollisionShape2D = $CollisionStand
# Collision when standing.
@onready var collision_crouch: CollisionShape2D = $CollisionCrouch
# Collision when crouching.
@onready var da_stand: CollisionShape2D = $DamageableArea/DAStand
# Damage hitbox when standing.
@onready var da_crouch: CollisionShape2D = $DamageableArea/DACrouch
# Damage hitbox when crouching.
@onready var one_way_shape_cast: ShapeCast2D = $OneWayShapeCast
# Used for one-way platform detection.
@onready var animation_player: AnimationPlayer = $AnimationPlayer
# Controls animations.
@onready var attack_area: AttackArea = $AttackArea
# Attack hitbox.
@onready var damageable_area: DamageableArea = $DamageableArea
# Area that receives damage.
@onready var label: Label = $Label
# Debug label showing state.
@onready var laser: Laser = $LaserOrigin/laser
# Built-in laser used for aiming and channeling.


#TUNABLE STATS

@export var walk_speed: float = 80.0
# Ground speed while walking.
@export var run_speed: float = 240.0
# Ground speed while running.
@export var air_velocity: float = 250.0
# Horizontal speed while airborne.
@export var max_fall_speed: float = 600.0
# Maximum downward velocity.
@export var gravity: float = 980.0
# Gravity force applied every frame.
@export var respawn_position: Vector2
# Position player returns to on death.
@export var afk_threshold_seconds: float = 6.0
# Time before AFK state triggers.
@export var movement_lock_time: float = 1.5
# Default duration for movement lock.
@export var double_tap_threshold: float = 0.25
# Max time between taps to trigger run.



#ABILITIES

# Flags for unlocked abilities and mechanics.
var run: bool = false
var dash: bool = false
var dash_count: int = 0

var double_jump: bool = false
var jump_count: int = 0

var lightning: bool = false
var Chain_lightning: bool = false
var dark_blast: bool = false
var heavy_attack: bool = false
var power_up: bool = false
var ground_slam: bool = false
var morph: bool = false

var spell2: bool = false
var spell3: bool = false
var spell4: bool = false
var spell5: bool = false
var spell6: bool = false
var spell7: bool = false
var spell8: bool = false

var can_interact: bool = false
# True when player can interact with objects.



#STATE MACHINE

# All available states.
var states: Array[PlayerState] = []

# Current and previous state.
var current_state: PlayerState
var previous_state: PlayerState

# Key state references for quick access.
var idle: PlayerState
var take_damage: PlayerState
var death: PlayerState

var cast_finished: bool = false
# True once shared Cast animation finishes.



#PLAYER STATS

# Internal health values.
var _hp: float = 20
var _max_hp: float = 20

# Current health with clamping and UI update.
var hp: float:
	get: return _hp
	set(value):
		_hp = clampf(value, 0, _max_hp)
		Messages.player_health_changed.emit(_hp, _max_hp)

# Maximum health with validation.
var max_hp: float:
	get: return _max_hp
	set(value):
		_max_hp = maxf(value, 1.0)
		_hp = clampf(_hp, 0, _max_hp)
		Messages.player_health_changed.emit(_hp, _max_hp)



#GENERAL STATE

# Movement input direction.
var direction: Vector2 = Vector2.ZERO

# Multiplier applied to gravity.
var gravity_multiplier: float = 1.0

# Whether player can move.
var can_move: bool = true

# Time since last input (AFK tracking).
var last_input_time: float = 0.0

# Time when last horizontal tap happened.
var last_tap_time: float = 0.0

# Last horizontal direction tapped.
var last_tap_dir: float = 0.0

# True when a successful double tap has armed running.
var wants_to_run: bool = false



#LIFECYCLE

func _ready() -> void:

	# Ensure only one player exists.
	add_to_group("Player")
	var players = get_tree().get_nodes_in_group("Player")

	if players.size() > 1:
		for p in players:
			if p != self:
				queue_free()
				return

	# Move player to root for global control.
	if get_parent() != get_tree().root:
		call_deferred("reparent", get_tree().root)

	initialize_states()

	# Set respawn position if not defined.
	if respawn_position == Vector2.ZERO:
		respawn_position = global_position

	# Connect global signals.
	Messages.player_healed.connect(_on_player_healed)
	Messages.back_to_title_screen.connect(queue_free)
	Messages.input_hint_changed.connect(_on_input_hint_changed)

	# Connect damage handling.
	if damageable_area:
		damageable_area.damage_taken.connect(_on_damage_taken)

	# Listen for shared cast animation finishing.
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

	# Initialize built-in laser.
	if laser:
		laser.is_casting = false
		laser.is_channeling = false

	hp = max_hp
	_update_label()



#STATE INITIALIZATION

func initialize_states() -> void:

	states.clear()

	# Collect all child states.
	for state in $States.get_children():
		if state is PlayerState:
			states.append(state)
			state.player = self

	# Assign key states.
	for state in states:
		if state.name.to_lower() == "idle":
			idle = state
		elif state.name.to_lower() == "takedamage":
			take_damage = state
		elif state is PlayerStateDeath:
			death = state

	# Start in idle.
	change_state(idle)



#STATE SWITCHING

# Changes current state and handles transitions.
func change_state(new_state: PlayerState) -> void:

	if new_state == null or new_state == current_state:
		return

	if current_state:
		current_state.exit()

	previous_state = current_state
	current_state = new_state

	current_state.enter()
	_update_label()



#DEBUG

# Updates on-screen state label.
func _update_label() -> void:

	if label and current_state:
		label.text = str(current_state.display_name if "display_name" in current_state else current_state.name)



#INPUT

func _unhandled_input(event: InputEvent) -> void:

	if not can_move:
		return

	last_input_time = 0.0

	if event.is_action_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	if event.is_action_pressed("action"):
		Messages.player_interacted.emit(self)

	elif event.is_action_pressed("pause"):

		if get_tree().paused:
			return

		var pause_menu = preload("res://World/Testing/pause_menu2.tscn").instantiate()
		get_tree().current_scene.add_child(pause_menu)
		return

	if current_state:
		var new_state = current_state.handle_input(event)
		if new_state != null:
			change_state(new_state)



#PROCESS

func _process(delta: float) -> void:

	if not can_move:
		return

	last_input_time += delta

	# Enter AFK state if inactive.
	if last_input_time >= afk_threshold_seconds:
		var afk_state = $States.get_node_or_null("AFK")
		if afk_state and current_state != afk_state:
			change_state(afk_state)

	update_direction()

	# Let state update.
	if current_state:
		var new_state = current_state.process(delta)
		if new_state != null:
			change_state(new_state)



#PHYSICS

func _physics_process(delta: float) -> void:

	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Apply gravity.
	velocity.y += gravity * delta * gravity_multiplier
	velocity.y = clampf(velocity.y, -1000.0, max_fall_speed)

	move_and_slide()

	# Let state handle physics.
	if current_state:
		var new_state = current_state.physics_process(delta)
		if new_state != null:
			change_state(new_state)

	# Update built-in laser.
	update_laser()



#LASER

# Updates built-in laser position and state flags.
func update_laser() -> void:
	if not laser:
		return

	# Use original laser origin node.
	laser.global_position = $LaserOrigin.global_position

	# Keep laser node unrotated.
	laser.rotation = 0.0

	# Cast drives everything.
	laser.is_casting = current_state is PlayerStateCast
	laser.is_channeling = current_state is PlayerStateCast


#ANIMATION

# Handles animation finished callbacks.
func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Cast":
		cast_finished = true



#MOVEMENT INPUT

# Updates movement direction from input.
func update_direction() -> void:

	var prev_dir: Vector2 = direction

	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)

	# Detect double tap for run.
	if direction.x != 0.0 and prev_dir.x == 0.0:
		var current_time: float = Time.get_ticks_msec() / 1000.0

		if run and direction.x == last_tap_dir and (current_time - last_tap_time) <= double_tap_threshold:
			wants_to_run = true
		else:
			wants_to_run = false

		last_tap_time = current_time
		last_tap_dir = direction.x

	# Stop run when horizontal input stops.
	if direction.x == 0.0:
		wants_to_run = false

	# Flip sprite when changing horizontal direction.
	if prev_dir.x != direction.x and direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0

		if attack_area:
			attack_area.flip(direction.x)



#DAMAGE

# Handles incoming damage.
func _on_damage_taken(area: AttackArea) -> void:

	hp -= area.damage
	damage_taken.emit()

	# Decide next state.
	if hp <= 0 and death:
		change_state(death)

	elif take_damage:
		var dir = -1.0 if area.global_position.x > global_position.x else 1.0
		take_damage.dir = dir
		change_state(take_damage)



#HEALING

func _on_player_healed(amount: float) -> void:
	hp += amount



#INTERACTION

# Updates whether player can interact.
func _on_input_hint_changed(prompt_name: String) -> void:
	can_interact = (prompt_name == "interact")



#ABILITY CHECKS

func can_dash() -> bool:
	return dash and dash_count == 0

func can_morph() -> bool:
	return morph and not can_interact



#MOVEMENT CONTROL

# Disables player movement.
func lock_movement() -> void:
	can_move = false
	velocity = Vector2.ZERO

# Re-enables movement.
func unlock_movement() -> void:
	can_move = true

# Locks movement temporarily.
func lock_movement_with_timer(time: float = movement_lock_time) -> void:
	lock_movement()
	await get_tree().create_timer(time).timeout
	unlock_movement()



#DEATH / RESPAWN

# Handles player death and reset.
func die(reason: String = "unknown") -> void:

	print("Player died by %s" % reason)

	global_position = respawn_position
	velocity = Vector2.ZERO
	direction = Vector2.ZERO
	wants_to_run = false
	cast_finished = false

	if laser:
		laser.is_casting = false
		laser.is_channeling = false

	if current_state:
		current_state.exit()

	change_state(idle)
