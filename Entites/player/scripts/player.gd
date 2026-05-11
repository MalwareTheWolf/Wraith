class_name Player
extends CharacterBody2D

# Main player controller.
# Handles movement, state machine, combat, abilities, UI updates, and footsteps.

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

var hp: float:
	get:
		return _hp
	set(value):
		_hp = clampf(value, 0, _max_hp)
		Messages.player_health_changed.emit(_hp, _max_hp)

var max_hp: float:
	get:
		return _max_hp
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


func change_state(new_state: PlayerState) -> void:
	if new_state == null or new_state == current_state:
		return

	if current_state:
		current_state.exit()

	previous_state = current_state
	current_state = new_state

	current_state.enter()
	_sync_laser_state()


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

		var pause_menu = preload("uid://cb6mwupp2lujb").instantiate()
		get_tree().current_scene.add_child(pause_menu)
		return

	if current_state:
		var new_state = current_state.handle_input(event)
		if new_state != null:
			change_state(new_state)


func _process(delta: float) -> void:
	if not can_move:
		return

	last_input_time += delta

	update_direction()

	if current_state != null and current_state.name.to_lower() == "idle":
		if last_input_time >= afk_threshold_seconds:
			var afk_state: PlayerState = $States.get_node_or_null("AFK")
			if afk_state != null and current_state != afk_state:
				change_state(afk_state)
				return

	if current_state:
		var new_state: PlayerState = current_state.process(delta)
		if new_state != null:
			change_state(new_state)


func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_laser_transform()
		_sync_laser_state()
		return

	velocity.y += gravity * delta * gravity_multiplier
	velocity.y = clampf(velocity.y, -1000.0, max_fall_speed)

	if current_state:
		var new_state: PlayerState = current_state.physics_process(delta)
		if new_state != null:
			change_state(new_state)

	move_and_slide()
	handle_footsteps(delta)

	_update_laser_transform()
	_sync_laser_state()


func update_direction() -> void:
	var prev_dir: Vector2 = direction

	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)

	if direction.x != 0.0 and prev_dir.x == 0.0:
		var current_time: float = Time.get_ticks_msec() / 1000.0

		if run and direction.x == last_tap_dir and (current_time - last_tap_time) <= double_tap_threshold:
			wants_to_run = true
		else:
			wants_to_run = false

		last_tap_time = current_time
		last_tap_dir = direction.x

	if direction.x == 0.0:
		wants_to_run = false

	if prev_dir.x != direction.x and direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0

		if attack_area:
			attack_area.flip(direction.x)


func handle_footsteps(delta: float) -> void:
	if not is_on_floor():
		footstep_timer = 0.0
		return

	if abs(velocity.x) < footstep_min_speed:
		footstep_timer = 0.0
		return

	footstep_timer -= delta

	if footstep_timer <= 0.0:
		play_footstep()
		footstep_timer = footstep_interval


func get_surface_type() -> String:
	if ground_tilemap == null:
		return "default"

	var check_pos: Vector2 = global_position

	if one_way_shape_cast and one_way_shape_cast.is_colliding():
		check_pos = one_way_shape_cast.get_collision_point(0) + Vector2(0, 2)
	else:
		check_pos = global_position + Vector2(0, 20)

	var map_pos: Vector2i = ground_tilemap.local_to_map(ground_tilemap.to_local(check_pos))
	var tile_data: TileData = ground_tilemap.get_cell_tile_data(map_pos)

	if tile_data:
		var surface = tile_data.get_custom_data("surface")

		if surface != null and str(surface) != "":
			return str(surface).to_lower()

	return "default"


func play_footstep() -> void:
	if footstep_player == null:
		return

	var surface: String = get_surface_type()
	var sounds: Array = footstep_sounds.get(surface, [])

	if sounds.is_empty():
		return

	footstep_player.stream = sounds.pick_random()
	footstep_player.bus = "SFX"
	footstep_player.pitch_scale = randf_range(0.95, 1.05)
	footstep_player.play()


func _on_damage_taken(area: AttackArea) -> void:
	hp -= area.damage
	damage_taken.emit()

	if hp <= 0 and death:
		change_state(death)

	elif take_damage:
		var dir = -1.0 if area.global_position.x > global_position.x else 1.0
		take_damage.dir = dir
		change_state(take_damage)


func _update_laser_transform() -> void:
	if not laser:
		return

	laser.global_position = $LaserOrigin.global_position
	laser.player = self
	laser.facing_sign = -1.0 if sprite.flip_h else 1.0


func _sync_laser_state() -> void:
	if not laser:
		return

	var casting := current_state is PlayerStateCast
	laser.is_casting = casting
	laser.is_channeling = casting


func _on_player_healed(amount: float) -> void:
	hp += amount


func _on_input_hint_changed(prompt_name: String) -> void:
	can_interact = (prompt_name == "interact")


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Cast":
		cast_finished = true


func can_dash() -> bool:
	return dash and dash_count == 0


func can_morph() -> bool:
	return morph and not can_interact


func lock_movement() -> void:
	set_control_enabled(false)


func unlock_movement() -> void:
	set_control_enabled(true)


func set_control_enabled(value: bool) -> void:
	can_move = value

	if not can_move:
		velocity = Vector2.ZERO
		direction = Vector2.ZERO
		wants_to_run = false

		if idle != null:
			change_state(idle)


func lock_movement_with_timer(time: float = movement_lock_time) -> void:
	lock_movement()
	await get_tree().create_timer(time).timeout
	unlock_movement()


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
