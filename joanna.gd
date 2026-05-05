extends CharacterBody2D

signal boss_started
signal health_changed(current_hp: float, max_hp: float)
signal phase_two_started
signal boss_defeated

enum BossState {
	IDLE,
	INTRO,
	WALK,
	RUN,
	JUMP,
	ATTACK,
	REST,
	HEAL,
	BUFF,
	PHASE_TWO,
	DEAD
}
@export_group("Boss Music")
@export var music_outro_seconds: float = 7.0

@export_group("Debug")
@export var debug_enabled: bool = true
@export var fallback_detection_range: float = 250.0

@export_group("Stats")
@export var max_hp: float = 70.0
@export var phase_two_hp_threshold: float = 0.5

@export_group("Attack Spacing")
@export var combo_cooldown: float = 0.5

@export_group("Half HP Rules")
@export var holy_unlock_hp_threshold: float = 0.5

@export_group("Healing")
@export var healing_enabled: bool = true
@export var heal_chance_percent: int = 60
@export var heal_cooldown: float = 5.0
@export var heal_start_delay: float = 3.0
@export var heal_unlock_hp_threshold: float = 0.5
@export var small_heal_hp_threshold: float = 0.4
@export var small_heal_amount: float = 8.0
@export var small_heal_max_uses: int = 1
@export var big_heal_hp_threshold: float = 0.25
@export var big_heal_amount: float = 15.0
@export var big_heal_max_uses: int = 1

@export_group("Heal Interrupt")
@export var heal_knockback_force: float = 85.0
@export var heal_knockback_up_force: float = 90.0

@export_group("Movement")
@export var walk_speed: float = 50.0
@export var run_speed: float = 110.0
@export var dash_speed: float = 170.0
@export var jump_velocity: float = -360.0
@export var platform_jump_velocity: float = -430.0
@export var gravity: float = 980.0
@export var max_fall_speed: float = 600.0
@export var run_distance: float = 180.0
@export var chase_until_distance: float = 15.0
@export var facing_deadzone: float = 10.0
@export var jump_y_difference: float = 38.0
@export var platform_jump_x_range: float = 150.0
@export var jump_cooldown: float = 1.4
@export var close_attack_distance: float = 55.0
@export var overlap_distance: float = 22.0
@export var jump_reaction_delay: float = 0.55
@export var jump_response_chance: int = 35
@export var jump_min_y_difference: float = 110.0
@export var jump_min_x_distance: float = 100.0

@export_group("Boss AI")
@export var attack_cooldown: float = 1.0
@export var phase_two_attack_cooldown: float = 0.65
@export var attack_decision_chance: int = 45
@export var holy_attack_chance: int = 55
@export var max_buffs: int = 2
@export var buff_speed_multiplier: float = 1.15
@export var buff_damage_multiplier: float = 1.15

@export_group("Attack Damage")
@export var slash_damage: float = 1.0
@export var thrust_damage: float = 1.0
@export var dash_damage: float = 1.0
@export var holy_damage: float = 1.0
@export var combo_damage: float = 1.0
@export var air_damage: float = 1.0

@export_group("Attack Timing")
@export var thrust_active_time: float = 0.16
@export var dash_startup: float = 0.20

@export_group("Boss Intro")
@export var intro_duration: float = 1.0
@export var required_dialog_id: String = "boss_intro"
@export var require_dialog_before_start: bool = true

@export_group("Scenes")
@export var holy_projectile_scene: PackedScene
@export var slam_wave_scene: PackedScene

@export_group("Dash Control")
@export var dash_overshoot_distance: float = 90.0
@export var dash_wall_check_distance: float = 18.0
@export var dash_max_time: float = 0.75

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var thrust_hitbox: AttackArea = $thrust
@onready var slash_hitbox: AttackArea = $holy_slash
@onready var dash_hitbox: AttackArea = $holy_dash
@onready var combo_hitbox: AttackArea = $combo_boxes
@onready var air_above_hitbox: AttackArea = $air_above_attack

@onready var damageable_area: DamageableArea = $DamageableArea
@onready var attack_timer: Timer = $attack_timer
@onready var player_detector: Area2D = $PlayerDetector
@onready var floor_detector: RayCast2D = $FloorDetector
@onready var state_label: Label = $StateLabel
@onready var boss_music_player: AudioStreamPlayer = $BossMusicPlayer

@onready var movement: JoannaMovementController = $MovementController
@onready var attacks: JoannaAttackController = $AttackController
@onready var healing: JoannaHealingController = $HealingController
@onready var debug_controller: JoannaDebugController = $DebugController

var current_hp: float = 0.0
var state: BossState = BossState.IDLE
var last_debug_state: BossState = BossState.IDLE
var rest_locked: bool = false
var player: Node2D = null
var player_inside_detector: bool = false
var music_ending: bool = false
var active: bool = false
var intro_playing: bool = false
var dead: bool = false
var attacking: bool = false
var can_attack: bool = true
var phase_two: bool = false
var jump_response_pending: bool = false
var facing_dir: int = 1
var last_facing_debug_dir: int = 0
var sprite_faces_right_by_default: bool = true

var can_jump_attack: bool = true
var small_heals_used: int = 0
var big_heals_used: int = 0
var buffs_used: int = 0
var buffed: bool = false
var was_running: bool = false
var heal_interrupted: bool = false
var heal_locked: bool = false
var heal_cancel_recovering: bool = false
var last_attack_name: String = ""
var has_reached_half_hp_once: bool = false
var attack_spacing_locked: bool = false
var fight_start_time_msec: int = 0
var last_heal_time_msec: int = -999999

var animation_offsets: Dictionary[String, Vector2] = {
	"holy_buff": Vector2(-6.0, -7.0),
	"holy_dash_attack": Vector2(-6.0, 4.0),
	"dash": Vector2(-6.0, 4.0),
	"holy_heal": Vector2(-5.0, -4.0),
	"holy_big_heal": Vector2(-5.0, -4.0),
	"holy_slash": Vector2(17.0, -31.0),
	"combo_1": Vector2(22.0, -10.0),
	"thrust_attack": Vector2(18.0, -9.0)
}


func _ready() -> void:
	current_hp = max_hp
	sprite_faces_right_by_default = not sprite.flip_h

	attacks.disable_all_hitboxes()

	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	player_detector.body_entered.connect(_on_player_detector_body_entered)
	player_detector.body_exited.connect(_on_player_detector_body_exited)
	damageable_area.damage_taken.connect(_on_damage_taken)

	health_changed.emit(current_hp, max_hp)
	sprite.play("idle")

	debug_print("READY. Joanna loaded.")
	debug_print("HP: %s/%s" % [current_hp, max_hp])
	debug_print("Detected sprite faces right by default: %s" % sprite_faces_right_by_default)


func _physics_process(delta: float) -> void:
	if dead:
		debug_controller.update_state_label()
		return

	movement.apply_gravity(delta)
	update_sprite_offset()
	debug_controller.update_state_label()
	debug_controller.debug_state_change()

	if player == null:
		player = find_player()

	if not active and player != null:
		var distance_to_player: float = global_position.distance_to(player.global_position)

		if player_inside_detector and can_start_boss_fight():
			start_boss_fight()
			return

		if distance_to_player <= fallback_detection_range and can_start_boss_fight():
			start_boss_fight()
			return

	if not active or intro_playing:
		velocity.x = 0.0
		move_and_slide()
		return

	if player == null:
		player = find_player()

		if player == null:
			debug_print("ACTIVE but player is still NULL. Boss cannot move.")
			move_and_slide()
			return

	if active and rest_locked:
		velocity.x = 0.0
		move_and_slide()
		return

	if attacking:
		if heal_cancel_recovering:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)

		move_and_slide()
		return

	debug_print("Before AI | active:%s intro:%s attacking:%s rest:%s player:%s velocity:%s" % [
		active,
		intro_playing,
		attacking,
		rest_locked,
		player,
		velocity
	])

	boss_ai()

	debug_print("After AI | state:%s velocity:%s" % [
		BossState.keys()[state],
		velocity
	])

	move_and_slide()
	
func boss_ai() -> void:
	if player == null:
		return

	var x_distance: float = abs(player.global_position.x - global_position.x)
	var y_difference: float = player.global_position.y - global_position.y
	var distance: float = global_position.distance_to(player.global_position)

	movement.face_player()

	if x_distance <= overlap_distance:
		movement.step_out_of_player()
		return

	if not has_reached_half_hp_once and current_hp <= max_hp * holy_unlock_hp_threshold:
		has_reached_half_hp_once = true
		debug_print("Holy attacks unlocked permanently.")

	if not phase_two and current_hp < max_hp and current_hp <= max_hp * phase_two_hp_threshold:
		healing.enter_phase_two()
		return

	if attack_spacing_locked:
		if x_distance > close_attack_distance:
			movement.chase_player(distance)
		else:
			movement.hold_idle()
		return

	if should_queue_jump_response(y_difference, x_distance):
		queue_jump_response()
		return

	if x_distance > close_attack_distance:
		movement.chase_player(distance)
		return

	var heal_type: String = healing.choose_heal_type()
	if heal_type != "":
		healing.do_heal(heal_type)
		return

	if healing.should_buff():
		healing.do_buff()
		return

	if can_attack:
		debug_print("Close enough. Attacking instead of idling. X:%s" % x_distance)

		if has_reached_half_hp_once:
			attacks.execute_combo(attacks.pick_unlocked_combo())
		else:
			attacks.execute_combo(attacks.pick_phase_one_combo())

		return

	movement.hold_idle()


func can_start_boss_fight() -> bool:
	if not require_dialog_before_start:
		return true

	if required_dialog_id.strip_edges() == "":
		return true

	return SaveManager.has_flag("dialog_" + required_dialog_id)


func start_boss_fight() -> void:
	if active:
		return

	if not can_start_boss_fight():
		debug_print("Boss fight blocked. Missing flag: dialog_%s" % required_dialog_id)
		return

	player = find_player()

	if player == null:
		debug_print("WARNING: Boss fight started but player is NULL.")

	active = true
	intro_playing = true
	rest_locked = false
	attacking = false
	attack_spacing_locked = false
	can_attack = true
	heal_cancel_recovering = false
	heal_interrupted = false

	fight_start_time_msec = Time.get_ticks_msec()
	state = BossState.INTRO
	velocity = Vector2.ZERO

	debug_print("Boss fight flags reset. rest_locked:%s attacking:%s spacing:%s can_attack:%s player:%s" % [
		rest_locked,
		attacking,
		attack_spacing_locked,
		can_attack,
		player
	])

	boss_started.emit()

	if boss_music_player != null and not boss_music_player.playing:
		boss_music_player.play()

	debug_print("BOSS INTRO STARTED")

	sprite.play("idle")

	await get_tree().create_timer(intro_duration).timeout

	player = find_player()

	intro_playing = false
	rest_locked = false
	attacking = false
	attack_spacing_locked = false
	can_attack = true
	heal_cancel_recovering = false

	state = BossState.IDLE
	velocity = Vector2.ZERO

	debug_print("Intro finished. Boss unlocked. Player:%s" % player)
	debug_print("BOSS FIGHT STARTED")


func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		player = body
		player_inside_detector = true

		if can_start_boss_fight():
			start_boss_fight()


func _on_player_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		player_inside_detector = false


func find_player() -> Node2D:
	var lower_player: Node = get_tree().get_first_node_in_group("player")
	if lower_player is Node2D:
		debug_print("Found player by group 'player': %s" % lower_player.name)
		return lower_player as Node2D

	var upper_player: Node = get_tree().get_first_node_in_group("Player")
	if upper_player is Node2D:
		debug_print("Found player by group 'Player': %s" % upper_player.name)
		return upper_player as Node2D

	debug_print("No player found in groups 'player' or 'Player'.")
	return null


func _on_damage_taken(attack_area: AttackArea) -> void:
	if dead:
		return

	if state == BossState.HEAL and not heal_interrupted:
		heal_interrupted = true
		healing.cancel_heal_with_knockback(attack_area)

	take_damage(attack_area.damage)


func take_damage(amount: float) -> void:
	if dead:
		return

	var previous_hp: float = current_hp

	current_hp -= amount
	current_hp = max(current_hp, 0.0)
	health_changed.emit(current_hp, max_hp)

	debug_print("HP changed: %s -> %s / %s" % [previous_hp, current_hp, max_hp])

	if current_hp <= max_hp * holy_unlock_hp_threshold and not has_reached_half_hp_once:
		has_reached_half_hp_once = true
		debug_print("Holy attacks unlocked from damage threshold.")

	if current_hp <= 0.0:
		die()
		return

	flash_damage()


func flash_damage() -> void:
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.08).timeout

	if not dead:
		sprite.modulate = Color.WHITE


func die() -> void:
	dead = true
	active = false
	intro_playing = false
	attacking = false
	rest_locked = false
	attack_spacing_locked = false
	state = BossState.DEAD

	movement.stop_all_velocity()
	attacks.disable_all_hitboxes()

	play_music_outro()

	sprite.play("death")
	boss_defeated.emit()

	await sprite.animation_finished
	sprite.pause()


func _on_attack_timer_timeout() -> void:
	can_attack = true


func update_sprite_offset() -> void:
	var offset: Vector2 = animation_offsets.get(sprite.animation, Vector2.ZERO) as Vector2

	if sprite.flip_h:
		offset.x *= -1.0

	sprite.offset = offset

func should_queue_jump_response(y_difference: float, x_distance: float) -> bool:
	if jump_response_pending:
		return false

	if not can_jump_attack:
		return false

	if not is_on_floor():
		return false

	if y_difference > -jump_min_y_difference:
		return false

	if x_distance < jump_min_x_distance:
		return false

	var roll: int = randi() % 100
	return roll < jump_response_chance


func queue_jump_response() -> void:
	jump_response_pending = true
	debug_print("Delayed jump response queued.")

	await get_tree().create_timer(jump_reaction_delay).timeout

	jump_response_pending = false

	if dead or not active or intro_playing or attacking or rest_locked:
		return

	if player == null:
		return

	var x_distance: float = abs(player.global_position.x - global_position.x)
	var y_difference: float = player.global_position.y - global_position.y

	if y_difference <= -jump_min_y_difference and x_distance >= jump_min_x_distance:
		movement.jump_to_player()

func debug_print(message: String) -> void:
	if debug_enabled:
		print("[JoannaBoss] ", message)

func play_music_outro() -> void:
	if boss_music_player == null:
		return

	if music_ending:
		return

	music_ending = true

	if not boss_music_player.playing:
		return

	var stream_length: float = 0.0

	if boss_music_player.stream != null:
		stream_length = boss_music_player.stream.get_length()

	if stream_length > music_outro_seconds:
		boss_music_player.seek(max(stream_length - music_outro_seconds, 0.0))

	await get_tree().create_timer(music_outro_seconds).timeout

	if boss_music_player != null:
		boss_music_player.stop()
