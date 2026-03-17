class_name PlayerStateAttack
extends PlayerState

const AUDIO_ATTACK = preload("uid://bbgd8l2c7hv38")

@export var speed : float = 150

# What happens when this state is initialized?
func init() -> void:
	pass

# What happens when we enter this state?
func enter() -> void:
	print("ENTER Attack state")
	player.animation_player.play("Attack")  # capital A!
	player.animation_player.animation_finished.connect(_on_animation_finished)
	player.attack_area.activate()
	Audio.play_spatial_sound(AUDIO_ATTACK, player.global_position)

# What happens when we exit this state?
func exit() -> void:
	if player.animation_player.animation_finished.is_connected(_on_animation_finished):
		player.animation_player.animation_finished.disconnect(_on_animation_finished)
	player.attack_area.set_active(false)
	next_state = null

# What happens when an input is pressed?
func handle_input(_event : InputEvent) -> PlayerState:
	if _event.is_action_pressed("dash") and player.can_dash():
		return dash
	if _event.is_action_pressed("action") and player.can_morph():
		return ball
	if _event.is_action_pressed("jump") and player.is_on_floor():
		return jump
	return null

# What happens each process tick in this state?
func process(_delta: float) -> PlayerState:
	player.velocity.x = player.direction.x * speed
	return next_state

# Callback when animation finishes
func _on_animation_finished(anim_name : String) -> void:
	if anim_name == "Attack":
		if player.is_on_floor():
			next_state = idle
		else:
			next_state = fall
