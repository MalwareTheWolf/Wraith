class_name JoannaAttackController
extends Node

#ATTACK CONTROLLER
#Handles attack selection, hitbox activation, dash attacks, combo attacks, holy attacks, and attack cooldowns.


#NODE REFERENCES

@onready var boss = get_parent()


#ATTACK LISTS

var phase_one_combos: Array[String] = [
	"thrust",
	"combo"
]

var unlocked_combos: Array[String] = [
	"thrust",
	"combo",
	"holy_slash",
	"holy_dash"
]


#ATTACK TRACKING

var combo_use_count: int = 0
var last_combo_name: String = ""


#COMBO PICKING

func pick_phase_one_combo() -> String:
	return pick_attack_from_list(phase_one_combos)


func pick_unlocked_combo() -> String:
	return pick_attack_from_list(unlocked_combos)


func pick_attack_from_list(attack_list: Array[String]) -> String:
	var possible_attacks: Array[String] = attack_list.duplicate()

	if last_combo_name != "":
		possible_attacks.erase(last_combo_name)

	if last_combo_name == "combo":
		possible_attacks.erase("combo")

	if possible_attacks.is_empty():
		possible_attacks = attack_list.duplicate()

	var chosen_attack: String = possible_attacks.pick_random()

	last_combo_name = chosen_attack

	return chosen_attack


#COMBO EXECUTION

func execute_combo(combo_name: String) -> void:
	if boss.attacking:
		return

	match combo_name:
		"thrust":
			await do_thrust()

		"combo":
			await do_combo()

		"holy_slash":
			await do_holy_slash()

		"holy_dash":
			await do_holy_dash()


#THRUST ATTACK

func do_thrust() -> void:
	boss.attacking = true
	boss.can_attack = false
	boss.attack_spacing_locked = true
	boss.state = boss.BossState.ATTACK

	boss.velocity.x = 0.0

	face_player()

	boss.sprite.play("thrust_attack")

	await wait_for_animation_frame(3)
	await boss.get_tree().create_timer(0.1).timeout

	boss.thrust_hitbox.position.y = -4.0

	enable_hitbox(
		boss.thrust_hitbox,
		boss.thrust_damage
	)

	await boss.get_tree().create_timer(
		boss.thrust_active_time
	).timeout

	disable_all_hitboxes()

	boss.thrust_hitbox.position.y = 0.0

	await wait_for_animation_finish()

	finish_attack()


#COMBO ATTACK

func do_combo() -> void:
	boss.attacking = true
	boss.can_attack = false
	boss.attack_spacing_locked = true
	boss.state = boss.BossState.ATTACK

	boss.velocity.x = 0.0

	face_player()

	boss.sprite.play("combo_1")

	await wait_for_animation_frame(4)

	enable_hitbox(
		boss.combo_hitbox,
		boss.combo_damage
	)

	await boss.get_tree().create_timer(0.48).timeout

	disable_all_hitboxes()

	await wait_for_animation_frame(18)

	boss.thrust_hitbox.position.y = -4.0

	enable_hitbox(
		boss.thrust_hitbox,
		boss.thrust_damage
	)

	await boss.get_tree().create_timer(
		boss.thrust_active_time
	).timeout

	disable_all_hitboxes()

	boss.thrust_hitbox.position.y = 0.0

	await wait_for_animation_finish()

	combo_use_count += 1

	if combo_use_count >= 4:
		combo_use_count = 0
		await play_rest()

	finish_attack()


#HOLY SLASH

func do_holy_slash() -> void:
	boss.attacking = true
	boss.can_attack = false
	boss.attack_spacing_locked = true
	boss.state = boss.BossState.ATTACK

	boss.velocity.x = 0.0

	face_player()

	boss.sprite.play("holy_slash")

	await wait_for_animation_frame(5)

	enable_hitbox(
		boss.slash_hitbox,
		boss.holy_damage
	)

	await boss.get_tree().create_timer(0.2).timeout

	disable_all_hitboxes()

	await wait_for_animation_finish()

	finish_attack()


#HOLY DASH

func do_holy_dash() -> void:
	boss.attacking = true
	boss.can_attack = false
	boss.attack_spacing_locked = true
	boss.state = boss.BossState.ATTACK

	face_player()

	var starting_dir: int = boss.facing_dir

	if boss.player != null:
		boss.global_position.x = boss.player.global_position.x + float(starting_dir) * 20.0
		boss.global_position.y = boss.player.global_position.y
		face_player()

	boss.sprite.play("holy_dash_attack")

	await boss.get_tree().create_timer(
		boss.dash_startup
	).timeout

	enable_hitbox(
		boss.dash_hitbox,
		boss.dash_damage
	)

	var dash_timer: float = 0.0

	while dash_timer < boss.dash_max_time:
		if boss.movement.is_wall_in_dash_direction(
			boss.facing_dir
		):
			break

		boss.velocity.x = (
			float(boss.facing_dir)
			* boss.dash_speed
		)

		dash_timer += get_process_delta_time()

		await boss.get_tree().process_frame

	disable_all_hitboxes()

	boss.velocity.x = 0.0

	await wait_for_animation_finish()

	finish_attack()


#REST ANIMATION

func play_rest() -> void:
	boss.state = boss.BossState.REST
	boss.rest_locked = true
	boss.velocity = Vector2.ZERO

	boss.sprite.play("rest")

	await wait_for_animation_finish()

	boss.rest_locked = false


#HITBOX CONTROL

func enable_hitbox(
	hitbox: AttackArea,
	damage: float
) -> void:

	if hitbox == null:
		return

	hitbox.damage = damage

	flip_hitbox(hitbox)

	hitbox.monitoring = true
	hitbox.visible = true


func disable_all_hitboxes() -> void:
	var hitboxes: Array = [
		boss.thrust_hitbox,
		boss.slash_hitbox,
		boss.dash_hitbox,
		boss.combo_hitbox,
		boss.air_above_hitbox
	]

	for hitbox in hitboxes:
		if hitbox == null:
			continue

		hitbox.monitoring = false
		hitbox.visible = false


#HITBOX POSITIONING

func flip_hitbox(hitbox: Node2D) -> void:
	if hitbox == null:
		return

	# Uses the AttackArea flip function for normal hitbox direction.
	if hitbox.has_method("flip"):
		hitbox.flip(float(boss.facing_dir))

	# Positions holy slash slightly left when Joanna faces left.
	if hitbox == boss.slash_hitbox:
		if boss.facing_dir < 0:
			hitbox.position.x = -10.0
		else:
			hitbox.position.x = 10.0

		return

	# Positions regular hitboxes by their current editor offset.
	var pos := hitbox.position
	pos.x = abs(pos.x) * boss.facing_dir
	hitbox.position = pos


#COLLISION NODE LOOKUP

func get_first_collision_node(
	hitbox: Node
) -> Node2D:

	for child in hitbox.get_children():
		if child is CollisionShape2D:
			return child as Node2D

		if child is CollisionPolygon2D:
			return child as Node2D

	return null


#ATTACK FINISH

func finish_attack() -> void:
	boss.attacking = false
	boss.attack_spacing_locked = false
	boss.state = boss.BossState.IDLE

	boss.attack_timer.start(
		boss.phase_two_attack_cooldown
		if boss.phase_two
		else boss.attack_cooldown
	)


#FACE PLAYER

func face_player() -> void:
	if boss.player == null:
		return

	var dir: int = int(sign(
		boss.player.global_position.x
		- boss.global_position.x
	))

	if dir != 0:
		boss.movement.face_direction(dir)


#ANIMATION HELPERS

func wait_for_animation_finish() -> void:
	await boss.sprite.animation_finished


func wait_for_animation_frame(
	target_frame: int
) -> void:

	while boss.sprite.frame < target_frame:
		await boss.get_tree().process_frame
