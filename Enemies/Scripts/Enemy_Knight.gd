extends CharacterBody2D

enum State { IDLE, RUN, ATTACK, TAKE_DAMAGE, DEATH }

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_detector: Area2D = $PlayerDetector
@onready var floor_detector: RayCast2D = get_node_or_null("EnemyStateMachine/FloorDetector")
@onready var state_label: Label = $StateLabel
@onready var attack_area: AttackArea = $AttackArea
@onready var damageable_area: DamageableArea = $DamageableArea

@export var speed_run: float = 140.0
@export var gravity: float = 600.0
@export var attack_distance: float = 40.0
@export var run_distance: float = 220.0

@export var max_health: float = 3.0
@export var damage: float = 1.0
@export var attack_duration: float = 0.12
@export var attack_cooldown: float = 0.45
@export var knockback_force: float = 120.0

var health: float = 0.0
var current_state: State = State.IDLE
var player: Node2D = null
var facing_dir: int = 1

var attack_playing: bool = false
var attack_on_cooldown: bool = false
var hurt_playing: bool = false
var dead: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	health = max_health

	player_detector.body_entered.connect(_on_player_entered)
	player_detector.body_exited.connect(_on_player_exited)
	sprite.animation_finished.connect(_on_animation_finished)
	damageable_area.damage_taken.connect(_on_damage_taken)

	if attack_area != null:
		attack_area.damage = damage
		attack_area.set_active(false)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	update_facing()
	update_state()

	match current_state:
		State.IDLE:
			handle_idle()
		State.RUN:
			handle_run()
		State.ATTACK:
			handle_attack()
		State.TAKE_DAMAGE:
			handle_take_damage()
		State.DEATH:
			handle_death()

	move_and_slide()
	update_label()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

func update_facing() -> void:
	if player != null and is_instance_valid(player) and not dead:
		var dir_x: float = sign(player.global_position.x - global_position.x)
		if dir_x != 0.0:
			facing_dir = int(dir_x)

	sprite.flip_h = facing_dir < 0

	if attack_area != null:
		attack_area.flip(float(facing_dir))

func update_state() -> void:
	if dead:
		current_state = State.DEATH
		return

	if hurt_playing:
		current_state = State.TAKE_DAMAGE
		return

	if attack_playing:
		current_state = State.ATTACK
		return

	if player == null or not is_instance_valid(player):
		current_state = State.IDLE
		return

	var dist: float = global_position.distance_to(player.global_position)

	if dist <= attack_distance and not attack_on_cooldown:
		current_state = State.ATTACK
	elif dist <= run_distance:
		current_state = State.RUN
	else:
		current_state = State.IDLE

func handle_idle() -> void:
	velocity.x = 0.0
	if sprite.animation != "Idle":
		sprite.play("Idle")

func handle_run() -> void:
	velocity.x = float(facing_dir) * speed_run
	update_floor_ray()

	if floor_detector != null and not floor_detector.is_colliding():
		velocity.x = 0.0

	if sprite.animation != "Run":
		sprite.play("Run")

func handle_attack() -> void:
	velocity.x = 0.0

	if not attack_playing:
		start_attack()

func handle_take_damage() -> void:
	velocity.x = move_toward(velocity.x, 0.0, 25.0)

	if sprite.animation != "Take_Damage":
		sprite.play("Take_Damage")

func handle_death() -> void:
	velocity.x = 0.0

	if sprite.animation != "Death":
		sprite.play("Death")

func start_attack() -> void:
	attack_playing = true
	attack_on_cooldown = true

	if attack_area != null:
		attack_area.damage = damage

	var attack_anim: String = "Attack_" + str(rng.randi_range(1, 3))
	sprite.play(attack_anim)
	_do_attack_hit()

func _do_attack_hit() -> void:
	if attack_area == null:
		return

	attack_area.flip(float(facing_dir))
	attack_area.activate(attack_duration)

func update_floor_ray() -> void:
	if floor_detector != null:
		floor_detector.target_position.x = absf(floor_detector.target_position.x) * float(facing_dir)

func _on_animation_finished() -> void:
	if sprite.animation.begins_with("Attack_"):
		attack_playing = false
		_start_attack_cooldown()
	elif sprite.animation == "Take_Damage":
		hurt_playing = false
		if damageable_area != null:
			damageable_area.end_invulnerable()
	elif sprite.animation == "Death":
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _start_attack_cooldown() -> void:
	await get_tree().create_timer(attack_cooldown).timeout
	attack_on_cooldown = false

func _on_damage_taken(attack_area_source: AttackArea) -> void:
	if dead:
		return

	if hurt_playing:
		return

	health -= attack_area_source.damage
	print("Enemy health: ", health)

	if health <= 0.0:
		die()
		return

	hurt_playing = true

	if damageable_area != null:
		damageable_area.start_invulnerable()

	var source_pos: Vector2 = attack_area_source.global_position
	var knockback_dir: float = sign(global_position.x - source_pos.x)
	if knockback_dir == 0.0:
		knockback_dir = -float(facing_dir)

	velocity.x = knockback_dir * knockback_force
	sprite.play("Take_Damage")

func die() -> void:
	if dead:
		return

	dead = true
	hurt_playing = false
	attack_playing = false
	attack_on_cooldown = true
	current_state = State.DEATH
	velocity = Vector2.ZERO

	if attack_area != null:
		attack_area.set_active(false)

	if player_detector != null:
		player_detector.monitoring = false

	if damageable_area != null:
		damageable_area.start_invulnerable()
		damageable_area.monitoring = false

	sprite.play("Death")

func update_label() -> void:
	if state_label != null:
		state_label.text = State.keys()[current_state] + " | HP: " + str(health)

func _on_player_entered(body: Node) -> void:
	if dead:
		return

	if body.is_in_group("Player"):
		player = body as Node2D

func _on_player_exited(body: Node) -> void:
	if body == player:
		player = null
