class_name PlayerStateBall
extends PlayerState

# --- AUDIO ---
const MORPH_AUDIO = preload("uid://btsc86lmk1nis")
const MORPH_OUT_AUDIO = preload("uid://dhsq6lqs775q5")

# --- EXPORTS ---
@export var jump_velocity: float = 400.0

# --- STATE FLAGS ---
var on_floor: bool = false
var morph_locked: bool = false
var unmorph_requested: bool = false
var pending_unmorph_state: PlayerState = null

# --- OPTIONAL NODE REFERENCES ---
# These are null-safe now, so the state will still work if they are missing.
@onready var ball_ray_up: RayCast2D = get_node_or_null("BallRayUp") as RayCast2D
@onready var ball_ray_down: RayCast2D = get_node_or_null("BallRayDown") as RayCast2D

@onready var jump_audio: AudioStreamPlayer2D = get_node_or_null("JumpAudio") as AudioStreamPlayer2D
@onready var land_audio: AudioStreamPlayer2D = get_node_or_null("LandAudio") as AudioStreamPlayer2D
@onready var morph_walk_audio: AudioStreamPlayer2D = get_node_or_null("MorphWalkAudio") as AudioStreamPlayer2D


# --- ENTER STATE ---
func enter() -> void:
	if not player:
		return

	on_floor = player.is_on_floor()
	morph_locked = true
	unmorph_requested = false
	pending_unmorph_state = null

	_set_ball_collision()

	player.velocity.y -= 100.0

	if player.animation_player:
		player.animation_player.speed_scale = 1.0
		player.animation_player.play("Morph_In")

	Audio.play_spatial_sound(MORPH_AUDIO, player.global_position)

	_finish_morph_in_after_delay.call_deferred()


# --- EXIT STATE ---
func exit() -> void:
	if not player:
		return

	_stop_morph_walk_audio()

	if player.animation_player:
		player.animation_player.speed_scale = 1.0

	_set_stand_collision()

	morph_locked = false
	unmorph_requested = false
	pending_unmorph_state = null


# --- HANDLE INPUT ---
func handle_input(event: InputEvent) -> PlayerState:
	if morph_locked:
		return null

	# Unmorph
	if event.is_action_pressed("action"):
		if _can_stand():
			unmorph_requested = true
			morph_locked = true
			_stop_morph_walk_audio()

			if player.animation_player:
				player.animation_player.speed_scale = 1.0
				player.animation_player.play("Morph_Out")

			Audio.play_spatial_sound(MORPH_OUT_AUDIO, player.global_position)

			pending_unmorph_state = idle if player.is_on_floor() else fall
			_finish_unmorph_after_delay.call_deferred()

		return null

	# Jump
	if event.is_action_pressed("jump") and player.is_on_floor():
		# Optional one-way platform drop-through
		if Input.is_action_pressed("down") and player.one_way_shape_cast:
			player.one_way_shape_cast.force_shapecast_update()
			if player.one_way_shape_cast.is_colliding():
				player.position.y += 4.0
				return null

		player.velocity.y = -jump_velocity

		if jump_audio:
			jump_audio.play()

		VisualEffects.jump_dust(player.global_position)

	return null


# --- PROCESS ---
func process(_delta: float) -> PlayerState:
	if pending_unmorph_state != null and not morph_locked:
		var next_state: PlayerState = pending_unmorph_state
		pending_unmorph_state = null
		return next_state

	if morph_locked:
		_stop_morph_walk_audio()
		return null

	if player.direction.x != 0.0:
		if player.animation_player and player.animation_player.current_animation != "Morph_Walk":
			player.animation_player.play("Morph_Walk")

		if player.animation_player:
			player.animation_player.speed_scale = 1.0

		if player.is_on_floor():
			_play_morph_walk_audio()
		else:
			_stop_morph_walk_audio()
	else:
		if player.animation_player and player.animation_player.current_animation != "Morph_Walk":
			player.animation_player.play("Morph_Walk")

		if player.animation_player:
			player.animation_player.speed_scale = 0.0

		_stop_morph_walk_audio()

	return null


# --- PHYSICS PROCESS ---
func physics_process(_delta: float) -> PlayerState:
	if morph_locked:
		player.velocity.x = 0.0
	else:
		player.velocity.x = player.direction.x * player.move_speed

	# Landing check
	if on_floor:
		if not player.is_on_floor():
			on_floor = false
	else:
		if player.is_on_floor():
			on_floor = true
			VisualEffects.land_dust(player.global_position)

			if land_audio:
				land_audio.play()

	return null


# --- MORPH TIMING ---
func _finish_morph_in_after_delay() -> void:
	if not player or not player.animation_player:
		return

	var morph_time: float = player.animation_player.current_animation_length
	await get_tree().create_timer(morph_time).timeout

	if not player or player.current_state != self:
		return

	morph_locked = false

	if player.animation_player:
		player.animation_player.play("Morph_Walk")
		if player.direction.x == 0.0:
			player.animation_player.speed_scale = 0.0
		else:
			player.animation_player.speed_scale = 1.0


func _finish_unmorph_after_delay() -> void:
	if not player or not player.animation_player:
		morph_locked = false
		return

	var morph_time: float = player.animation_player.current_animation_length
	await get_tree().create_timer(morph_time).timeout

	if not player or player.current_state != self:
		return

	morph_locked = false


# --- AUDIO HELPERS ---
func _play_morph_walk_audio() -> void:
	if morph_walk_audio and not morph_walk_audio.playing:
		morph_walk_audio.play()


func _stop_morph_walk_audio() -> void:
	if morph_walk_audio and morph_walk_audio.playing:
		morph_walk_audio.stop()


# --- COLLISION HELPERS ---
func _set_ball_collision() -> void:
	if not player:
		return

	var shape: CapsuleShape2D = player.collision_stand.shape as CapsuleShape2D
	if shape:
		shape.radius = 11.0
		shape.height = 22.0

	player.collision_stand.position.y = -11.0

	if player.da_stand:
		player.da_stand.position.y = -11.0


func _set_stand_collision() -> void:
	if not player:
		return

	var shape: CapsuleShape2D = player.collision_stand.shape as CapsuleShape2D
	if shape:
		shape.radius = 8.0
		shape.height = 46.0

	player.collision_stand.position.y = -23.0

	if player.da_stand:
		player.da_stand.position.y = -23.0


# --- CHECK IF CAN UNMORPH ---
func _can_stand() -> bool:
	# If the rays are missing, do not crash.
	# Allow standing by default.
	if ball_ray_up == null or ball_ray_down == null:
		push_warning("BallRayUp/BallRayDown missing in Ball state. Allowing stand by default.")
		return true

	ball_ray_up.force_raycast_update()
	ball_ray_down.force_raycast_update()

	return not (ball_ray_up.is_colliding() or ball_ray_down.is_colliding())
