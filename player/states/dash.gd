class_name PlayerStateDash
extends PlayerState

const DASH_AUDIO = preload("uid://fp3pia3qydwj")

@export var duration: float = 0.25
@export var speed: float = 300.0
@export var effect_delay: float = 0.05
@export var dash_damage: float = 1.0

# Set this to the physics layer number your enemies use.
@export var enemy_collision_layer: int = 3

var dir: float = 1.0
var time: float = 0.0
var effect_time: float = 0.0
var cached_enemy_mask_enabled: bool = false

@onready var damageable_area: DamageableArea = %DamageableArea
@onready var dash_attack_area: AttackArea = %DashAttackArea


func init() -> void:
	pass


func enter() -> void:
	if player.animation_player:
		player.animation_player.play("Dash")

	time = duration
	effect_time = 0.0

	get_dash_direction()

	damageable_area.make_invulnerable(duration)

	Audio.play_spatial_sound(DASH_AUDIO, player.global_position)

	player.gravity_multiplier = 0.0
	player.velocity.y = 0.0
	player.dash_count += 1

	_disable_enemy_collision()
	_enable_dash_attack()

	var tween: Tween = create_tween()
	tween.tween_property(player.sprite, "modulate", Color(1, 1, 1, 0.5), duration * 0.5)
	tween.tween_property(player.sprite, "modulate", Color(1, 1, 1, 1), duration * 0.5)


func exit() -> void:
	player.gravity_multiplier = 1.0
	_restore_enemy_collision()
	_disable_dash_attack()


func handle_input(_event: InputEvent) -> PlayerState:
	if _event.is_action_pressed("action") and player.can_morph():
		return ball

	return null


func process(_delta: float) -> PlayerState:
	time -= _delta

	if time <= 0.0:
		if player.is_on_floor():
			return idle
		else:
			return fall

	effect_time -= _delta

	if effect_time < 0.0:
		effect_time = effect_delay
		player.sprite.ghost()

	return null


func physics_process(_delta: float) -> PlayerState:
	player.velocity.x = (speed * (time / duration) + speed) * dir
	_update_dash_attack_facing()
	return null


func get_dash_direction() -> void:
	dir = sign(player.direction.x)

	if dir == 0.0:
		dir = -1.0 if player.sprite.flip_h else 1.0


func _enable_dash_attack() -> void:
	if dash_attack_area == null:
		return

	dash_attack_area.damage = dash_damage
	dash_attack_area.flip(dir)
	dash_attack_area.set_active(true)


func _disable_dash_attack() -> void:
	if dash_attack_area == null:
		return

	dash_attack_area.set_active(false)


func _update_dash_attack_facing() -> void:
	if dash_attack_area == null:
		return

	dash_attack_area.flip(dir)


func _disable_enemy_collision() -> void:
	cached_enemy_mask_enabled = player.get_collision_mask_value(enemy_collision_layer)
	player.set_collision_mask_value(enemy_collision_layer, false)


func _restore_enemy_collision() -> void:
	player.set_collision_mask_value(enemy_collision_layer, cached_enemy_mask_enabled)
