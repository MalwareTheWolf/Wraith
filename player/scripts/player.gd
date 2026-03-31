class_name Player
extends CharacterBody2D

# --- SIGNALS ---
signal damage_taken

# --- NODE REFERENCES ---
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
@onready var laser: Laser = $LaserOrigin/laser


# --- TUNABLE STATS ---
@export var move_speed: float = 150.0
@export var air_velocity: float = 250.0
@export var max_fall_speed: float = 600.0
@export var gravity: float = 980.0
@export var respawn_position: Vector2
@export var afk_threshold_seconds: float = 6.0
@export var movement_lock_time: float = 1.5

# --- ABILITIES ---
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

# --- STATE MACHINE ---
var states: Array[PlayerState] = []
var current_state: PlayerState
var previous_state: PlayerState
var idle: PlayerState
var take_damage: PlayerState
var death: PlayerState

# --- PLAYER STATS ---
var _hp: float = 20
var _max_hp: float = 20
var hp: float:
	get: return _hp
	set(value):
		_hp = clampf(value, 0, _max_hp)
		Messages.player_health_changed.emit(_hp, _max_hp)
var max_hp: float:
	get: return _max_hp
	set(value):
		_max_hp = maxf(value, 1.0)
		_hp = clampf(_hp, 0, _max_hp)
		Messages.player_health_changed.emit(_hp, _max_hp)

# --- GENERAL STATE ---
var direction: Vector2 = Vector2.ZERO
var gravity_multiplier: float = 1.0
var can_move: bool = true
var last_input_time: float = 0.0

# --- LIFECYCLE ---
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

	hp = max_hp
	_update_label()

# --- STATE INITIALIZATION ---
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

# --- STATE SWITCHING ---
func change_state(new_state: PlayerState) -> void:
	if new_state == null or new_state == current_state:
		return
	if current_state:
		current_state.exit()
	previous_state = current_state
	current_state = new_state
	current_state.enter()
	_update_label()

# --- DEBUG ---
func _update_label() -> void:
	if label and current_state:
		label.text = str(current_state.display_name if "display_name" in current_state else current_state.name)

# --- INPUT ---
func _unhandled_input(event: InputEvent) -> void:
	if not can_move:
		return
	last_input_time = 0.0
	if event.is_action_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
	if event.is_action_pressed("action"):
		Messages.player_interacted.emit(self)
	elif event.is_action_pressed("pause"):
		if not get_tree().paused:
			get_tree().paused = true
			var pause_menu = preload("res://pause_menu/pause_menu.tscn").instantiate()
			add_child(pause_menu)
			return
	if current_state:
		var new_state = current_state.handle_input(event)
		if new_state != null:
			change_state(new_state)

# --- PROCESS ---
func _process(delta: float) -> void:
	if not can_move:
		return
	last_input_time += delta
	if last_input_time >= afk_threshold_seconds:
		var afk_state = $States.get_node_or_null("AFK")
		if afk_state and current_state != afk_state:
			change_state(afk_state)
	update_direction()
	if current_state:
		var new_state = current_state.process(delta)
		if new_state != null:
			change_state(new_state)

# --- PHYSICS ---
func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Apply gravity
	velocity.y += gravity * delta * gravity_multiplier
	velocity.y = clampf(velocity.y, -1000.0, max_fall_speed)
	move_and_slide()

	if current_state:
		var new_state = current_state.physics_process(delta)
		if new_state != null:
			change_state(new_state)

	# --- LASER LOGIC ---
	if laser:
		# Anchor laser to eye
		laser.global_position = $LaserOrigin.global_position

		# Update casting
		laser.is_casting = Input.is_action_pressed("laser")

		# Rotate toward mouse
		var dir = (get_global_mouse_position() - laser.global_position).normalized()
		laser.rotation = dir.angle()

# --- MOVEMENT INPUT ---
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

# --- DAMAGE ---
func _on_damage_taken(area: AttackArea) -> void:
	hp -= area.damage
	damage_taken.emit()
	if hp <= 0 and death:
		change_state(death)
	elif take_damage:
		var dir = -1.0 if area.global_position.x > global_position.x else 1.0
		take_damage.dir = dir
		change_state(take_damage)

# --- HEALING ---
func _on_player_healed(amount: float) -> void:
	hp += amount

# --- INTERACTION ---
func _on_input_hint_changed(prompt_name: String) -> void:
	can_interact = (prompt_name == "interact")

# --- ABILITY CHECKS ---
func can_dash() -> bool:
	return dash and dash_count == 0
func can_morph() -> bool:
	return morph and not can_interact

# --- MOVEMENT CONTROL ---
func lock_movement() -> void:
	can_move = false
	velocity = Vector2.ZERO
func unlock_movement() -> void:
	can_move = true
func lock_movement_with_timer(time: float = movement_lock_time) -> void:
	lock_movement()
	await get_tree().create_timer(time).timeout
	unlock_movement()

# --- DEATH / RESPAWN ---
func die(reason: String = "unknown") -> void:
	print("Player died by %s" % reason)
	global_position = respawn_position
	velocity = Vector2.ZERO
	direction = Vector2.ZERO
	if current_state:
		current_state.exit()
	change_state(idle)
