class_name JoannaHealingController
extends Node

@onready var boss = get_parent()


func choose_heal_type() -> String:
	if not boss.healing_enabled:
		return ""

	if boss.heal_locked or boss.attacking or boss.heal_cancel_recovering:
		return ""

	if not boss.can_attack:
		return ""

	if boss.current_hp >= boss.max_hp:
		return ""

	var hp_percent: float = boss.current_hp / boss.max_hp

	if hp_percent > boss.heal_unlock_hp_threshold:
		return ""

	var now_msec: int = Time.get_ticks_msec()
	var fight_elapsed: float = float(now_msec - boss.fight_start_time_msec) / 1000.0
	var heal_elapsed: float = float(now_msec - boss.last_heal_time_msec) / 1000.0

	if fight_elapsed < boss.heal_start_delay:
		return ""

	if heal_elapsed < boss.heal_cooldown:
		return ""

	var can_big_heal: bool = hp_percent <= boss.big_heal_hp_threshold and boss.big_heals_used < boss.big_heal_max_uses
	var can_small_heal: bool = hp_percent <= boss.small_heal_hp_threshold and boss.small_heals_used < boss.small_heal_max_uses

	if not can_big_heal and not can_small_heal:
		return ""

	var roll: int = randi() % 100

	if roll >= boss.heal_chance_percent:
		boss.debug_print("Heal skipped. Roll:%s Chance:%s" % [roll, boss.heal_chance_percent])
		return ""

	if can_big_heal:
		return "big"

	if can_small_heal:
		return "small"

	return ""


func do_heal(heal_type: String) -> void:
	if boss.heal_locked:
		return

	boss.attacking = true
	boss.can_attack = false
	boss.heal_locked = true
	boss.heal_interrupted = false
	boss.heal_cancel_recovering = false
	boss.last_heal_time_msec = Time.get_ticks_msec()

	boss.attack_timer.start()
	boss.state = boss.BossState.HEAL
	boss.movement.stop_velocity()
	boss.attacks.disable_all_hitboxes()

	var amount: float = 0.0
	var heal_anim: String = "holy_heal"

	if heal_type == "big":
		boss.big_heals_used += 1
		amount = boss.big_heal_amount
		heal_anim = "holy_big_heal"
	else:
		boss.small_heals_used += 1
		amount = boss.small_heal_amount
		heal_anim = "holy_heal"

	boss.debug_print("Heal started | Type:%s Amount:%s" % [heal_type, amount])

	boss.sprite.play(heal_anim)

	while boss.sprite.animation == heal_anim and boss.sprite.is_playing() and not boss.heal_interrupted and not boss.dead:
		await boss.get_tree().process_frame

	if boss.dead:
		return

	if boss.heal_interrupted:
		boss.debug_print("Heal interrupted. No HP restored.")
		await play_interrupted_rest()
		boss.attacking = false
		boss.heal_locked = false
		boss.heal_cancel_recovering = false
		boss.state = boss.BossState.IDLE
		return

	boss.current_hp = min(boss.current_hp + amount, boss.max_hp)
	boss.health_changed.emit(boss.current_hp, boss.max_hp)

	boss.debug_print("Heal completed | Restored:%s HP:%s/%s" % [
		amount,
		boss.current_hp,
		boss.max_hp
	])

	boss.attacking = false
	boss.heal_locked = false
	boss.state = boss.BossState.IDLE

	boss.attack_spacing_locked = true
	await boss.get_tree().create_timer(boss.combo_cooldown).timeout
	boss.attack_spacing_locked = false


func cancel_heal_with_knockback(attack_area: AttackArea) -> void:
	if boss.state != boss.BossState.HEAL:
		return

	boss.heal_cancel_recovering = true
	boss.heal_interrupted = true
	boss.attacks.disable_all_hitboxes()

	boss.sprite.stop()

	var knock_dir: int = int(sign(boss.global_position.x - attack_area.global_position.x))

	if knock_dir == 0:
		knock_dir = -boss.facing_dir

	boss.velocity.x = float(knock_dir) * boss.heal_knockback_force
	boss.velocity.y = -boss.heal_knockback_up_force

	boss.state = boss.BossState.REST


func play_interrupted_rest() -> void:
	boss.attacks.disable_all_hitboxes()
	boss.movement.stop_all_velocity()

	boss.rest_locked = true
	boss.attacking = true
	boss.state = boss.BossState.REST

	boss.sprite.play("rest")

	boss.debug_print("Rest opening started: interrupted heal")

	await boss.attacks.wait_for_animation_done("rest")

	boss.rest_locked = false
	boss.velocity.x = 0.0

	boss.debug_print("Rest opening finished: interrupted heal")


func should_buff() -> bool:
	if boss.buffs_used >= boss.max_buffs:
		return false

	if boss.buffed:
		return false

	if boss.current_hp > boss.max_hp * 0.65:
		return false

	if not boss.can_attack:
		return false

	if boss.attacking:
		return false

	return randi() % 100 < 25


func do_buff() -> void:
	if boss.attacking:
		return

	boss.attacking = true
	boss.can_attack = false
	boss.attack_timer.start()
	boss.state = boss.BossState.BUFF
	boss.movement.stop_velocity()
	boss.attacks.disable_all_hitboxes()

	boss.buffs_used += 1

	boss.sprite.play("holy_buff")

	await boss.attacks.wait_for_animation_done("holy_buff")

	if boss.dead:
		return

	boss.buffed = true

	boss.walk_speed *= boss.buff_speed_multiplier
	boss.run_speed *= boss.buff_speed_multiplier
	boss.dash_speed *= boss.buff_speed_multiplier
	boss.slash_damage *= boss.buff_damage_multiplier
	boss.thrust_damage *= boss.buff_damage_multiplier
	boss.dash_damage *= boss.buff_damage_multiplier
	boss.holy_damage *= boss.buff_damage_multiplier
	boss.combo_damage *= boss.buff_damage_multiplier
	boss.air_damage *= boss.buff_damage_multiplier

	boss.attacking = false
	boss.state = boss.BossState.IDLE


func enter_phase_two() -> void:
	if boss.phase_two:
		return

	if boss.current_hp >= boss.max_hp:
		return

	boss.phase_two = true
	boss.state = boss.BossState.PHASE_TWO
	boss.attacking = true
	boss.movement.stop_velocity()
	boss.attacks.disable_all_hitboxes()

	boss.sprite.play("holy_buff")

	await boss.attacks.wait_for_animation_done("holy_buff")

	if boss.dead:
		return

	boss.walk_speed *= 1.2
	boss.run_speed *= 1.25
	boss.dash_speed *= 1.2

	boss.slash_damage *= 1.25
	boss.thrust_damage *= 1.25
	boss.dash_damage *= 1.25
	boss.holy_damage *= 1.25
	boss.combo_damage *= 1.25
	boss.air_damage *= 1.25

	boss.attack_timer.wait_time = boss.phase_two_attack_cooldown
	boss.phase_two_started.emit()

	boss.attacking = false
	boss.state = boss.BossState.IDLE
