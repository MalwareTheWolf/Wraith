@icon("uid://b044gwmkvmxmt")
class_name PlayerStateAFK extends PlayerState 

# How long to wait before going AFK (seconds)
@export var afk_threshold: float = 6.0

# Tracks time without input
var idle_timer: float = 0.0
var is_afk: bool = false

func init() -> void:
	idle_timer = 0.0
	is_afk = false

func handle_input(event: InputEvent) -> PlayerState:
	# Any input exits AFK immediately
	if is_afk and event.is_pressed():
		is_afk = false
		# Return to previous state
		if player.previous_state:
			return player.previous_state
	# Not AFK yet, just reset timer
	idle_timer = 0.0
	return self

func process(delta: float) -> PlayerState:
	if is_afk:
		# Remain in AFK state until input
		return self

	# Count idle time
	idle_timer += delta
	if idle_timer >= afk_threshold:
		is_afk = true
		# Play AFK animation
		if player.animation_player:
			player.animation_player.play("AFK")
	return self

func enter() -> void:
	# Reset timer when entering state
	idle_timer = 0.0
	is_afk = false

func exit() -> void:
	# Optional: revert animation when leaving AFK
	if player.animation_player:
		player.animation_player.play("Idle")  # Replace with your default idle animation
