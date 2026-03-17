class_name PlayerStateDeath extends PlayerState

const DEATH_AUDIO = preload("uid://cru1tm8vatgix")

# What happens when we enter this state?
func enter() -> void:
	if player.animation_player:
		player.animation_player.play("Death")  # Capitalized to match your convention
		await player.animation_player.animation_finished
	Audio.play_spatial_sound(DEATH_AUDIO, player.global_position)
	Audio.play_music(null)
	PlayerHud.show_game_over()

# What happens when we exit this state?
func exit() -> void:
	pass

# What happens when an input is pressed?
func handle_input(_event : InputEvent) -> PlayerState:
	return null

# What happens each process tick in this state?
func process(_delta: float) -> PlayerState:
	return null

# What happens each physics_process tick in this state?
func physics_process(_delta: float) -> PlayerState:
	player.velocity.x = 0
	return null
