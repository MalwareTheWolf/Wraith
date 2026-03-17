class_name PlayerStateTakeDamage extends PlayerState

@export var move_speed : float = 100
@export var invulnerable_duration : float = 0.5
var time : float = 0.0
var dir : float = 1.0
@onready var damageable_area: DamageableArea = %DamageableArea
@onready var hurt_audio: AudioStreamPlayer2D = %HurtAudio

# What happens when this state is initialized?
func init() -> void:
	if not damageable_area.damage_taken.is_connected(_on_damage_taken):
		damageable_area.damage_taken.connect(_on_damage_taken)

# What happens when we enter this state?
func enter() -> void:
	player.animation_player.play("take_damage")
	time = max(player.animation_player.current_animation_length, 0.1)
	damageable_area.make_invulnerable(invulnerable_duration)
	hurt_audio.play()
	VisualEffects.camera_shake(2.0)
	# Flip sprite to face attacker
	player.sprite.flip_h = dir < 0

# What happens when we exit this state?
func exit() -> void:
	pass

# What happens when an input is pressed?
func handle_input(_event : InputEvent) -> PlayerState:
	return null

# What happens each process tick in this state?
func process(_delta: float) -> PlayerState:
	time -= _delta
	if time <= 0:
		if player.hp <= 0:
			return death
		return idle
	return null

# What happens each physics_process tick in this state?
func physics_process(_delta: float) -> PlayerState:
	player.velocity.x = move_speed * dir
	return null

# What happens when the player takes damage
func _on_damage_taken(attack_area : AttackArea) -> void:
	if player.current_state == death:
		return
	# Only enter state if not currently invulnerable
	if not damageable_area.is_invulnerable():
		player.change_state(self)
		if attack_area.global_position.x < player.global_position.x:
			dir = 1.0
		else:
			dir = -1.0
