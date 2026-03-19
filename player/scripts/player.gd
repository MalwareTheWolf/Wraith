class_name Player
extends CharacterBody2D

signal damage_taken

#region --- ONREADY VARIABLES
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_sprite: Sprite2D = $AttackSprite2D
@onready var collision_stand: CollisionShape2D = $CollisionStand
@onready var collision_crouch: CollisionShape2D = $CollisionCrouch
@onready var da_stand: CollisionShape2D = $DamageableArea/DAStand
@onready var da_crouch: CollisionShape2D = $DamageableArea/DACrouch
@onready var one_way_shape_cast: ShapeCast2D = $OneWayShapeCast
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_area: AttackArea = $AttackArea
@onready var damageable_area: DamageableArea = $DamageableArea
@onready var label: Label = $Label
#endregion

#region --- EXPORT VARIABLES
@export var move_speed : float = 150.0
@export var air_velocity : float = 250.0  # Speed while in the air
@export var max_fall_speed : float = 600.0
@export var gravity : float = 980.0
@export var respawn_position : Vector2
@export var afk_threshold_seconds : float = 6.0
@export var movement_lock_time : float = 1.5
#endregion

#region --- ABILITIES
var dash : bool = false
var dash_count : int = 0
var double_jump : bool = false
var jump_count : int = 0
var lightning : bool = false
var Chain_lightning : bool = false
var dark_blast : bool = false
var heavy_attack : bool = false
var power_up : bool = false
var ground_slam : bool = false
var morph : bool = false
var spell2 : bool = false
var spell3 : bool = false
var spell4 : bool = false
var spell5 : bool = false
var spell6 : bool = false
var spell7 : bool = false
var spell8 : bool = false
var can_interact : bool = false
#endregion

#region --- STATE MACHINE VARIABLES
var states: Array[PlayerState] = []

var current_state: PlayerState
var previous_state: PlayerState

# References to key states
var idle: PlayerState
var take_damage: PlayerState
var death: PlayerState
#endregion

#region --- PLAYER STATS
var _hp : float = 20
var _max_hp : float = 20

var hp : float:
	get: return _hp
	set(value):
		_hp = clampf(value, 0, _max_hp)
		Messages.player_health_changed.emit(_hp, _max_hp)

var max_hp : float:
	get: return _max_hp
	set(value):
		_max_hp = maxf(value, 1.0)
		_hp = clampf(_hp, 0, _max_hp)
		Messages.player_health_changed.emit(_hp, _max_hp)
#endregion

#region --- STANDARD VARIABLES
var direction: Vector2 = Vector2.ZERO
var gravity_multiplier: float = 1.0
var can_move: bool = true
var last_input_time: float = 0.0  # AFK tracking
#endregion

# --- READY ---
func _ready() -> void:
	add_to_group("Player")

	# Prevent duplicates
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 1:
		for p in players:
			if p != self:
				queue_free()
				return
	# Move player to root
	if get_parent() != get_tree().root:
		call_deferred("reparent", get_tree().root)

	initialize_states()

	if respawn_position == Vector2.ZERO:
		respawn_position = global_position

	# Connect signals
	Messages.player_healed.connect(_on_player_healed)
	Messages.back_to_title_screen.connect(queue_free)
	Messages.input_hint_changed.connect(_on_input_hint_changed)

	if damageable_area:
		damageable_area.damage_taken.connect(_on_damage_taken)

	hp = max_hp
	_update_label()
	pass

# --- INITIALIZE STATES ---
func initialize_states() -> void:
	states.clear()
	for state in $States.get_children():
		if state is PlayerState:
			states.append(state)
			state.player = self
	pass

	# Assign key states for easy access
	for state in states:
		if state.name.to_lower() == "idle":
			idle = state
		elif state.name.to_lower() == "takedamage":
			take_damage = state
		elif state is PlayerStateDeath:
			death = state
	pass

	# Enter idle at start
	change_state(idle)
	pass

# --- CHANGE STATE ---
func change_state(new_state: PlayerState) -> void:
	if new_state == null or new_state == current_state:
		return
	if current_state:
		current_state.exit()
	previous_state = current_state
	current_state = new_state
	current_state.enter()
	_update_label()
	pass

# --- UPDATE LABEL ---
func _update_label() -> void:
	if label and current_state:
		label.text = str(current_state.display_name if "display_name" in current_state else current_state.name)
	pass

# --- INPUT ---
func _unhandled_input(event: InputEvent) -> void:
	if not can_move:
		return

	# Reset AFK timer
	last_input_time = 0.0

	# Jump release for variable jump height
	if event.is_action_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	pass

	# Interact and pause
	if event.is_action_pressed("action"):
		Messages.player_interacted.emit(self)
	elif event.is_action_pressed("pause"):
		if not get_tree().paused:
			get_tree().paused = true
			var pause_menu = preload("res://pause_menu/pause_menu.tscn").instantiate()
			add_child(pause_menu)
			return
	pass

	# Let current state handle input
	if current_state:
		var new_state = current_state.handle_input(event)
		if new_state != null:
			change_state(new_state)
	pass

# --- PROCESS ---
func _process(delta: float) -> void:
	if not can_move:
		return

	last_input_time += delta

	# AFK check
	if last_input_time >= afk_threshold_seconds:
		var afk_state = $States.get_node_or_null("AFK")
		if afk_state and current_state != afk_state:
			change_state(afk_state)
	pass

	# Update movement input
	update_direction()

	# Let current state process
	if current_state:
		var new_state = current_state.process(delta)
		if new_state != null:
			change_state(new_state)
	pass

# --- PHYSICS PROCESS ---
func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity.y += gravity * delta * gravity_multiplier
	velocity.y = clampf(velocity.y, -1000.0, max_fall_speed)
	move_and_slide()

	# Let current state handle physics
	if current_state:
		var new_state = current_state.physics_process(delta)
		if new_state != null:
			change_state(new_state)
	pass

# --- UPDATE DIRECTION ---
func update_direction() -> void:
	var prev_dir = direction
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)
	if prev_dir.x != direction.x and direction.x != 0:
		sprite.flip_h = direction.x < 0
		if attack_area:
			attack_area.flip(direction.x)
	pass

# --- DAMAGE HANDLING ---
func _on_damage_taken(area: AttackArea) -> void:
	hp -= area.damage
	damage_taken.emit()
	pass

	# Decide which state to enter
	if hp <= 0 and death:
		change_state(death)
	elif take_damage:
		var dir = -1.0 if area.global_position.x > global_position.x else 1.0
		take_damage.dir = dir
		change_state(take_damage)
	pass

# --- HEALING ---
func _on_player_healed(amount: float) -> void:
	hp += amount
	pass

# --- INPUT HINT ---
func _on_input_hint_changed(prompt_name: String) -> void:
	can_interact = (prompt_name == "interact")
	pass

# --- ABILITY CHECKS ---
func can_dash() -> bool:
	return dash and dash_count == 0
	pass

func can_morph() -> bool:
	return morph and not can_interact
	pass

# --- MOVEMENT LOCKS ---
func lock_movement() -> void:
	can_move = false
	velocity = Vector2.ZERO
	pass

func unlock_movement() -> void:
	can_move = true
	pass

func lock_movement_with_timer(time: float = movement_lock_time) -> void:
	lock_movement()
	await get_tree().create_timer(time).timeout
	unlock_movement()
	pass

# --- MANUAL DEATH ---
func die(reason: String = "unknown") -> void:
	print("Player died by %s" % reason)
	global_position = respawn_position
	velocity = Vector2.ZERO
	direction = Vector2.ZERO
	if current_state:
		current_state.exit()
	change_state(idle)
	pass
