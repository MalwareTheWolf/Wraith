class_name JoannaHealingController
extends Node

#HEALING CONTROLLER
#Handles:
# - Healing
# - Buffing
# - Phase 2 transition
# - Heal interruption
# - Heal logic


#NODE REFERENCES

@onready var boss = get_parent()


#HEAL CHOICES

func choose_heal_type() -> String:
	if not boss.healing_enabled:
		return ""

	if boss.heal_locked:
		return ""

	if boss.attacking:
		return ""

	if boss.current_hp >= boss.max_hp:
		return ""

	var elapsed: float = (
		float(Time.get_ticks_msec()
		- boss.last_heal_time_msec)
		/ 1000.0
	)

	if elapsed < boss.heal_cooldown:
		return ""

	var hp_percent: float = (
		boss.current_hp / boss.max_hp
	)

	if (
		hp_percent <= boss.big_heal_hp_threshold
		and boss.big_heals_used
		< boss.big_heal_max_uses
	):
		return "big"

	if (
		hp_percent <= boss.small_heal_hp_threshold
		and boss.small_heals_used
		< boss.small_heal_max_uses
	):
		return "small"

	return ""


#HEAL EXECUTION

func do_heal(type: String) -> void:
	if boss.heal_locked:
		return

	boss.attacking = true
	boss.heal_locked = true
	boss.heal_interrupted = false
	boss.state = boss.BossState.HEAL
	boss.velocity.x = 0.0

	match type:
		"small":
			await do_small_heal()

		"big":
			await do_big_heal()

	if boss.heal_interrupted:
		return

	boss.last_heal_time_msec = (
		Time.get_ticks_msec()
	)

	boss.attacking = false
	boss.heal_locked = false
	boss.state = boss.BossState.IDLE

	boss.attack_timer.start(
		boss.attack_cooldown
	)


#SMALL HEAL

func do_small_heal() -> void:
	boss.sprite.play("holy_heal")

	await boss.get_tree().create_timer(
		boss.heal_start_delay
	).timeout

	if boss.heal_interrupted:
		return

	boss.current_hp += (
		boss.small_heal_amount
	)

	boss.current_hp = min(
		boss.current_hp,
		boss.max_hp
	)

	boss.small_heals_used += 1

	boss.health_changed.emit(
		boss.current_hp,
		boss.max_hp
	)

	await boss.sprite.animation_finished


#BIG HEAL

func do_big_heal() -> void:
	boss.sprite.play("holy_big_heal")

	await boss.get_tree().create_timer(
		boss.heal_start_delay
	).timeout

	if boss.heal_interrupted:
		return

	boss.current_hp += (
		boss.big_heal_amount
	)

	boss.current_hp = min(
		boss.current_hp,
		boss.max_hp
	)

	boss.big_heals_used += 1

	boss.health_changed.emit(
		boss.current_hp,
		boss.max_hp
	)

	await boss.sprite.animation_finished


#BUFFING

func should_buff() -> bool:
	if boss.buffed:
		return false

	if boss.buffs_used >= boss.max_buffs:
		return false

	if not boss.phase_two:
		return false

	return true


func do_buff() -> void:
	boss.attacking = true
	boss.state = boss.BossState.BUFF
	boss.velocity.x = 0.0

	boss.sprite.play("holy_buff")

	await boss.sprite.animation_finished

	boss.walk_speed *= (
		boss.buff_speed_multiplier
	)

	boss.run_speed *= (
		boss.buff_speed_multiplier
	)

	boss.dash_speed *= (
		boss.buff_speed_multiplier
	)

	boss.slash_damage *= (
		boss.buff_damage_multiplier
	)

	boss.combo_damage *= (
		boss.buff_damage_multiplier
	)

	boss.dash_damage *= (
		boss.buff_damage_multiplier
	)

	boss.buffed = true
	boss.buffs_used += 1

	boss.attacking = false
	boss.state = boss.BossState.IDLE


#PHASE TWO

func enter_phase_two() -> void:
	if boss.phase_two:
		return

	boss.phase_two = true
	boss.state = boss.BossState.PHASE_TWO
	boss.attacking = true
	boss.velocity.x = 0.0

	boss.phase_two_started.emit()

	boss.sprite.play("holy_buff")

	await boss.sprite.animation_finished

	boss.attacking = false
	boss.state = boss.BossState.IDLE


#HEAL INTERRUPTION

func cancel_heal_with_knockback(
	attack_area: AttackArea
) -> void:

	boss.heal_interrupted = true
	boss.heal_locked = false
	boss.heal_cancel_recovering = true

	var dir: float = sign(
		boss.global_position.x
		- attack_area.global_position.x
	)

	if dir == 0.0:
		dir = 1.0

	boss.velocity.x = (
		dir
		* boss.heal_knockback_force
	)

	boss.velocity.y = (
		-boss.heal_knockback_up_force
	)

	boss.attacking = true
	boss.state = boss.BossState.REST

	boss.attacks.disable_all_hitboxes()

	await boss.get_tree().create_timer(
		0.4
	).timeout

	boss.heal_cancel_recovering = false
	boss.attacking = false
	boss.state = boss.BossState.IDLE
