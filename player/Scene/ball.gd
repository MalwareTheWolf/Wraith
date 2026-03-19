class_name PlayerStateBall
extends PlayerState

const MORPH_AUDIO = preload("uid://btsc86lmk1nis")
const MORPH_OUT_AUDIO = preload("uid://dhsq6lqs775q5")

@export var jump_velocity : float = 400

var on_floor : bool = true

@onready var ball_ray_up: RayCast2D = %BallRayUp
@onready var ball_ray_down: RayCast2D = %BallRayDown
@onready var jump_audio: AudioStreamPlayer2D = %JumpAudio
@onready var land_audio: AudioStreamPlayer2D = %LandAudio


func enter() -> void:
	if not player:
		return

	player.animation_player.play("Ball")

	var shape := player.collision_stand.shape as CapsuleShape2D
	if shape:
		shape.radius = 11.0
		shape.height = 22.0

	player.collision_stand.position.y = -11

	if player.da_stand:
		player.da_stand.position.y = -11

	player.velocity.y -= 100
	Audio.play_spatial_sound(MORPH_AUDIO, player.global_position)


func exit() -> void:
	if not player:
		return

	player.animation_player.speed_scale = 1

	var shape := player.collision_stand.shape as CapsuleShape2D
	if shape:
		shape.radius = 8.0
		shape.height = 46.0

	player.collision_stand.position.y = -23

	if player.da_stand:
		player.da_stand.position.y = -23

	player.velocity.y -= 100

	Audio.play_spatial_sound(MORPH_OUT_AUDIO, player.global_position)


func handle_input(event: InputEvent) -> PlayerState:
	if event.is_action_pressed("action"):
		if _can_stand():
			if player.is_on_floor():
				return idle
			return fall

	if event.is_action_pressed("jump"):
		if player.is_on_floor():
			if Input.is_action_pressed("down") and player.one_way_shape_cast:
				player.one_way_shape_cast.force_shapecast_update()
				if player.one_way_shape_cast.is_colliding():
					player.position.y += 4
					return null

			player.velocity.y -= jump_velocity
			jump_audio.play()
			VisualEffects.jump_dust(player.global_position)

	return null


func process(_delta: float) -> PlayerState:
	if player.direction.x == 0:
		player.animation_player.speed_scale = 0
	else:
		player.animation_player.speed_scale = 1

	return null


func physics_process(_delta: float) -> PlayerState:
	player.velocity.x = player.direction.x * player.move_speed

	if on_floor:
		if not player.is_on_floor():
			on_floor = false
	else:
		if player.is_on_floor():
			on_floor = true
			VisualEffects.land_dust(player.global_position)
			land_audio.play()

	return next_state


func _can_stand() -> bool:
	ball_ray_up.force_raycast_update()
	ball_ray_down.force_raycast_update()

	if ball_ray_down.is_colliding() and ball_ray_up.is_colliding():
		return false

	return true
