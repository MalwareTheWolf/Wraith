class_name JoannaAttackController
extends Node

@onready var boss = get_parent()

var phase_one_attack_bag: Array[String] = []
var holy_attack_bag: Array[String] = []

func pick_attack_without_repeat(attacks: Array[String]) -> String:
	if attacks.is_empty():
		return ""

	if attacks.size() <= 1:
		boss.last_attack_name = attacks[0]
		return attacks[0]

	var filtered: Array[String] = []

	for attack_name: String in attacks:
		if attack_name != boss.last_attack_name:
			filtered.append(attack_name)

	if filtered.is_empty():
		filtered = attacks

	var chosen: String = filtered.pick_random()
	boss.last_attack_name = chosen

	boss.debug_print("Attack picked: %s from %s" % [chosen, filtered])

	return chosen


func pick_phase_one_combo() -> Array[String]:
	var possible: Array[String] = []

	if not boss.is_on_floor():
		possible.append("air_attack")

		if boss.player != null and boss.player.global_position.y < boss.global_position.y - 30.0:
			possible.append("air_above_attack")

		return [pick_from_bag(possible, phase_one_attack_bag, "phase one air")]

	possible = [
		"dash",
		"combo_1",
		"air_attack",
		"thrust_attack"
	]

	if boss.player != null and boss.player.global_position.y < boss.global_position.y - 30.0:
		possible.append("air_above_attack")

	return [pick_from_bag(possible, phase_one_attack_bag, "phase one")]


func pick_unlocked_combo() -> Array[String]:
	var possible: Array[String] = []

	if not boss.is_on_floor():
		possible.append("air_attack")

		if boss.player != null and boss.player.global_position.y < boss.global_position.y - 30.0:
			possible.append("air_above_attack")

		return [pick_from_bag(possible, holy_attack_bag, "unlocked air")]

	possible = [
		"dash",
		"combo_1",
		"air_attack",
		"thrust_attack"
	]

	if boss.player != null and boss.player.global_position.y < boss.global_position.y - 30.0:
		possible.append("air_above_attack")

	if boss.has_reached_half_hp_once:
		var holy_roll: int = randi() % 100

		if holy_roll < boss.holy_attack_chance:
			possible.append("holy_dash")
			possible.append("holy_projectile")

	var chosen: String = pick_from_bag(possible, holy_attack_bag, "unlocked")

	match chosen:
		"holy_dash":
			return ["holy_dash"]
		"holy_projectile":
			return ["holy_projectile"]
		_:
			return [chosen]


func execute_combo(combo: Array[String]) -> void:
	if boss.attacking or boss.dead or boss.attack_spacing_locked:
		return

	if combo.is_empty():
		return

	boss.can_attack = false
	boss.attack_spacing_locked = true
	boss.attack_timer.start()
	boss.attacking = true
	boss.was_running = false

	var used_rest_attack: bool = false

	boss.debug_print("Combo started: %s" % combo)

	for attack_name: String in combo:
		if boss.dead or boss.player == null:
			break

		boss.movement.face_player()
		boss.debug_print("Attack used: %s" % attack_name)

		match attack_name:
			"dash":
				await do_dash_attack()

			"air_above_attack":
				await do_air_above_attack()

			"air_attack":
				await do_air_attack()

			"thrust_attack":
				await do_thrust_attack()

			"combo_1":
				await do_combo_1()
				used_rest_attack = true

			"holy_dash":
				await do_holy_dash_attack()
				used_rest_attack = true

			"holy_projectile":
				await do_holy_attack()

			_:
				boss.debug_print("Unknown attack name: %s" % attack_name)

		disable_all_hitboxes()

	if used_rest_attack and not boss.dead:
		await play_rest("heavy attack finished")

	boss.attacking = false
	boss.state = boss.BossState.IDLE

	await boss.get_tree().create_timer(boss.combo_cooldown).timeout

	boss.attack_spacing_locked = false
	boss.debug_print("Combo cooldown finished.")


func play_rest(reason: String) -> void:
	disable_all_hitboxes()
	boss.movement.stop_all_velocity()

	boss.rest_locked = true
	boss.attacking = true
	boss.state = boss.BossState.REST

	boss.sprite.play("rest")

	boss.debug_print("Rest opening started: %s" % reason)

	await wait_for_animation_done("rest")

	boss.rest_locked = false

	boss.debug_print("Rest opening finished.")

func do_air_above_attack() -> void:
	boss.state = boss.BossState.ATTACK
	boss.movement.face_player()

	var dir: int = boss.facing_dir
	var target_position: Vector2 = boss.player.global_position + Vector2(-40.0 * float(dir), -80.0)

	boss.sprite.play("air_above_attack")

	boss.global_position = target_position
	boss.velocity = Vector2.ZERO

	await boss.get_tree().create_timer(0.20).timeout

	boss.movement.face_player()
	boss.velocity.y = 300.0

	disable_all_hitboxes()

	boss.air_above_hitbox.damage = boss.air_damage
	boss.air_above_hitbox.flip(float(boss.facing_dir))
	boss.air_above_hitbox.activate(0.24)

	await wait_for_animation_done("air_above_attack")

	disable_all_hitboxes()

	boss.global_position.x += -float(boss.facing_dir) * 24.0
	boss.velocity = Vector2.ZERO


func do_air_attack() -> void:
	boss.state = boss.BossState.ATTACK
	boss.movement.face_player()

	var dir: int = boss.facing_dir

	boss.sprite.play("air_attack")

	boss.velocity.x = float(dir) * boss.run_speed * 2.2
	boss.velocity.y = boss.jump_velocity

	await boss.get_tree().create_timer(0.16).timeout

	disable_all_hitboxes()

	boss.combo_hitbox.damage = boss.air_damage
	boss.combo_hitbox.flip(float(dir))
	boss.combo_hitbox.activate(0.28)

	await wait_for_animation_done("air_attack")

	disable_all_hitboxes()

	boss.velocity.x = 0.0
	boss.global_position.x += -float(dir) * 20.0

func do_thrust_attack() -> void:
	boss.state = boss.BossState.ATTACK
	boss.movement.stop_velocity()
	boss.movement.face_player()

	boss.sprite.play("thrust_attack")

	await boss.get_tree().create_timer(0.18).timeout

	disable_all_hitboxes()

	boss.thrust_hitbox.position.y = 0.0
	boss.thrust_hitbox.damage = boss.thrust_damage
	boss.thrust_hitbox.flip(float(boss.facing_dir))
	boss.thrust_hitbox.activate(boss.thrust_active_time)

	await wait_for_animation_done("thrust_attack")

	disable_all_hitboxes()

func do_dash_attack() -> void:
	boss.state = boss.BossState.ATTACK
	boss.movement.face_player()

	var dir: int = boss.facing_dir
	var dash_time: float = 0.0

	boss.sprite.play("dash")

	await boss.get_tree().create_timer(boss.dash_startup).timeout

	disable_all_hitboxes()

	boss.dash_hitbox.damage = boss.dash_damage
	boss.dash_hitbox.flip(float(dir))
	boss.dash_hitbox.set_active(true)

	while dash_time < boss.dash_max_time and not boss.dead:
		if boss.movement.is_wall_in_dash_direction(dir):
			break

		boss.velocity.x = float(dir) * boss.dash_speed
		boss.move_and_slide()

		dash_time += boss.get_physics_process_delta_time()
		await boss.get_tree().physics_frame

	boss.velocity.x = 0.0
	boss.dash_hitbox.set_active(false)

	await wait_for_animation_done("dash")

	disable_all_hitboxes()

func do_combo_1() -> void:
	boss.state = boss.BossState.ATTACK
	boss.movement.stop_velocity()
	boss.movement.face_player()

	boss.sprite.play("combo_1")

	await boss.get_tree().create_timer(0.15).timeout

	disable_all_hitboxes()

	boss.combo_hitbox.damage = boss.combo_damage
	boss.combo_hitbox.flip(float(boss.facing_dir))
	boss.combo_hitbox.set_active(true)

	await boss.get_tree().create_timer(1.65).timeout

	boss.movement.face_player()

	boss.combo_hitbox.set_active(false)

	boss.thrust_hitbox.position.y = 0.0
	boss.thrust_hitbox.damage = boss.thrust_damage
	boss.thrust_hitbox.flip(float(boss.facing_dir))
	boss.thrust_hitbox.set_active(true)

	await boss.get_tree().create_timer(boss.thrust_active_time).timeout

	boss.thrust_hitbox.set_active(false)

	await wait_for_animation_done("combo_1")

	disable_all_hitboxes()


func do_holy_dash_attack() -> void:
	if not boss.has_reached_half_hp_once:
		await do_dash_attack()
		return

	boss.state = boss.BossState.ATTACK
	boss.movement.face_player()

	var dir: int = boss.facing_dir
	var dash_time: float = 0.0
	var desired_x: float = boss.player.global_position.x + float(dir) * boss.dash_overshoot_distance

	boss.movement.stop_velocity()
	boss.sprite.play("holy_dash_attack")

	await boss.get_tree().create_timer(boss.dash_startup).timeout

	disable_all_hitboxes()

	boss.dash_hitbox.damage = boss.dash_damage
	boss.dash_hitbox.flip(float(dir))
	boss.dash_hitbox.set_active(true)

	while abs(boss.global_position.x - desired_x) > 8.0 and not boss.dead:
		if boss.movement.is_wall_in_dash_direction(dir):
			break

		boss.velocity.x = float(dir) * boss.dash_speed
		boss.move_and_slide()

		dash_time += boss.get_physics_process_delta_time()

		if dash_time >= boss.dash_max_time:
			break

		await boss.get_tree().physics_frame

	boss.velocity.x = 0.0
	boss.dash_hitbox.set_active(false)

	if not boss.movement.is_wall_in_dash_direction(dir):
		boss.global_position.x = desired_x

	await wait_for_animation_done("holy_dash_attack")

	disable_all_hitboxes()


func do_holy_attack() -> void:
	if not boss.has_reached_half_hp_once:
		await do_combo_1()
		return

	boss.state = boss.BossState.ATTACK
	boss.movement.stop_velocity()
	boss.movement.face_player()

	boss.sprite.play("holy_big_heal")

	await boss.get_tree().create_timer(0.55).timeout

	spawn_holy_projectile()

	await wait_for_animation_done("holy_big_heal")


func spawn_holy_projectile() -> void:
	if boss.holy_projectile_scene == null:
		boss.debug_print("holy_projectile_scene is not assigned.")
		return

	var projectile: Node = boss.holy_projectile_scene.instantiate()
	boss.get_tree().current_scene.add_child(projectile)

	if projectile is Node2D:
		var projectile_2d: Node2D = projectile as Node2D
		projectile_2d.global_position = boss.global_position + Vector2(30.0 * float(boss.facing_dir), -20.0)

	projectile.set("direction", (boss.player.global_position - boss.global_position).normalized())
	projectile.set("damage", boss.holy_damage)


func wait_for_animation_done(animation_name: String) -> void:
	if boss.sprite.animation != animation_name:
		boss.sprite.play(animation_name)

	while boss.sprite.animation == animation_name and boss.sprite.is_playing():
		await boss.get_tree().process_frame


func pick_from_bag(possible: Array[String], bag: Array[String], label: String) -> String:
	# Remove attacks from the bag that are no longer allowed.
	for i: int in range(bag.size() - 1, -1, -1):
		if not possible.has(bag[i]):
			bag.remove_at(i)

	# Refill the bag only when everything has been used.
	if bag.is_empty():
		for attack_name: String in possible:
			bag.append(attack_name)

		boss.debug_print("Attack bag refilled [%s]: %s" % [label, bag])

	var chosen: String = bag.pick_random()
	bag.erase(chosen)

	boss.last_attack_name = chosen

	boss.debug_print("Attack picked from bag [%s]: %s | remaining:%s" % [
		label,
		chosen,
		bag
	])

	return chosen

func disable_all_hitboxes() -> void:
	if boss.thrust_hitbox != null:
		boss.thrust_hitbox.set_active(false)

	if boss.slash_hitbox != null:
		boss.slash_hitbox.set_active(false)

	if boss.dash_hitbox != null:
		boss.dash_hitbox.set_active(false)

	if boss.combo_hitbox != null:
		boss.combo_hitbox.set_active(false)

	if boss.air_above_hitbox != null:
		boss.air_above_hitbox.set_active(false)
