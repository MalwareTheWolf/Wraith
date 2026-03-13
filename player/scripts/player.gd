class_name Player
extends CharacterBody2D
# Main player controller.
# Handles movement, gravity, state machine logic, pause menu access,
# persistence between scenes, healing, and respawning.

const DEBUG_JUMP_INDICATOR = preload("uid://b37qe6ik3s8if")

#region /// on ready variables
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_stand: CollisionShape2D = $CollisionStand
@onready var collision_crouch: CollisionShape2D = $CollisionCrouch
@onready var one_way_shape_cast: ShapeCast2D = $OneWayShapeCast
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_area: AttackArea = %AttackArea

#endregion


#region /// export variables
@export var move_speed : float = 150.0
@export var air_velocity : float = 250.0
@export var respawn_position : Vector2
@export var max_fall_speed : float = 600.0
@export var movement_lock_time : float = 1.5
#endregion


#region /// State Machine Variables
var states : Array[PlayerState]

var current_state : PlayerState:
	get: return states.front()

var previous_state : PlayerState:
	get: return states[1]
#endregion


#region /// player stats (fixed recursion bug)
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


#region /// abilities
var dash : bool = false
var double_jump : bool = false
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
#endregion


#region /// standard variables
var direction : Vector2 = Vector2.ZERO
var gravity : float = 980.0
var gravity_multiplier : float = 1.0
var can_move : bool = true
#endregion


func _ready() -> void:
	add_to_group("Player")

	# Prevent duplicate persistent players
	var players := get_tree().get_nodes_in_group("Player")

	if players.size() > 1:
		for p in players:
			if p != self:
				queue_free()
				return

	# Ensure persistent player
	if get_parent() != get_tree().root:
		call_deferred("reparent", get_tree().root)

	initialize_states()

	if respawn_position == Vector2.ZERO:
		respawn_position = global_position

	Messages.player_healed.connect(_on_player_healed)
	Messages.back_to_title_screen.connect(queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if !can_move:
		return

	if event.is_action_pressed("action"):
		Messages.player_interacted.emit(self)

	elif event.is_action_pressed("pause"):

		if get_tree().paused:
			return

		get_tree().paused = true

		var pause_menu = preload("uid://dnv5ffvrxoh8t").instantiate()
		get_tree().root.add_child(pause_menu)
		return

	change_state(current_state.handle_input(event))

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_MINUS:
			if Input.is_key_pressed(KEY_SHIFT):
				max_hp -= 10
			else:
				hp -= 2
		elif event.keycode == KEY_EQUAL:
			if Input.is_key_pressed(KEY_SHIFT):
				max_hp += 10
			else:
				hp += 2


func _process(_delta: float) -> void:
	if !can_move:
		return

	update_direction()
	change_state(current_state.process(_delta))


func _physics_process(_delta: float) -> void:
	if !can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity.y += gravity * _delta * gravity_multiplier
	velocity.y = clampf(velocity.y, -1000.0, max_fall_speed)

	move_and_slide()
	change_state(current_state.physics_process(_delta))


func initialize_states() -> void:
	states = []

	for c in $States.get_children():
		if c is PlayerState:
			states.append(c)
			c.player = self

	if states.size() == 0:
		return

	for state in states:
		state.init()

	change_state(current_state)
	current_state.enter()

	$Label.text = current_state.name


func change_state(new_state : PlayerState) -> void:
	if new_state == null:
		return
	elif new_state == current_state:
		return

	if current_state:
		current_state.exit()

	states.push_front(new_state)
	current_state.enter()

	states.resize(3)
	$Label.text = current_state.name


func update_direction() -> void:
	var prev_direction : Vector2 = direction

	var x_axis = Input.get_axis("left", "right")
	var y_axis = Input.get_axis("up", "down")

	direction = Vector2(x_axis, y_axis)

	if prev_direction.x != direction.x and direction.x != 0:
		sprite.flip_h = direction.x < 0


func add_debug_indicator(color : Color = Color.RED) -> void:
	var d : Node2D = DEBUG_JUMP_INDICATOR.instantiate()

	get_tree().root.add_child(d)
	d.global_position = global_position
	d.modulate = color

	await get_tree().create_timer(3.0).timeout
	d.queue_free()


func die(reason: String = "unknown") -> void:
	print("Player died by %s" % reason)

	global_position = respawn_position
	velocity = Vector2.ZERO
	direction = Vector2.ZERO

	if current_state:
		current_state.exit()
		current_state.enter()


func lock_movement() -> void:
	can_move = false
	velocity = Vector2.ZERO


func unlock_movement() -> void:
	can_move = true


func lock_movement_with_timer(time : float = movement_lock_time) -> void:
	lock_movement()

	await get_tree().create_timer(time).timeout

	unlock_movement()


func _on_player_healed(amount : float) -> void:
	hp += amount
