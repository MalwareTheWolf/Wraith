class_name PlayerStateDash extends PlayerState

const DASH_AUDIO = preload("uid://fp3pia3qydwj")

@export var duration : float = 0.25
@export var speed : float = 300.0
@export var effect_delay : float = 0.05

var dir : float = 1.0
var time : float = 0.0
var effect_time : float = 0.0

@onready var damageable_area: DamageableArea = %DamageArea

# What happens when this state is initialized?
func init() -> void:
	pass

# What happens when we enter this state?
func enter() -> void:
	if player.animation_player:
		player.animation_player.play("Dash")  # Capitalized to match convention
	time = duration
	effect_time = 0.0
	get_dash_direction()
	damageable_area.make_invulnerable(duration)
	Audio.play_spatial_sound(DASH_AUDIO, player.global_position)

	player.gravity_multiplier = 0.0
	player.velocity.y = 0
	player.dash_count += 1
	player.sprite.tween_color(duration)

# What happens when we exit this state?
func exit() -> void:
	player.gravity_multiplier = 1.0

# What happens when an input is pressed?
func handle_input(_event : InputEvent) -> PlayerState:
	if _event.is_action_pressed("action") and player.can_morph():
		return ball
	return null

# What happens each process tick in this state?
func process(_delta: float) -> PlayerState:
	time -= _delta
	if time <= 0:
		if player.is_on_floor():
			return idle
		else:
			return fall

	effect_time -= _delta
	if effect_time < 0:
		effect_time = effect_delay
		player.sprite.ghost()
	return null

# What happens each physics_process tick in this state?
func physics_process(_delta: float) -> PlayerState:
	player.velocity.x = (speed * (time / duration) + speed) * dir
	return next_state

# Determines dash direction based on sprite orientation
func get_dash_direction() -> void:
	dir = 1.0
	if player.sprite.flip_h:
		dir = -1.0
