class_name EnemyKnight extends CharacterBody2D

# Enemy AI controller for a knight-type enemy.
# Handles movement, combat, damage, and state transitions.


#STATE ENUM

# Defines all possible behavior states for the enemy.
enum State { IDLE, RUN, ATTACK, TAKE_DAMAGE, DEATH }



#NODE REFERENCES

# Main animated sprite controlling visuals.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Detects when player enters or exits range.
@onready var player_detector: Area2D = $PlayerDetector

# Raycast used to prevent walking off edges.
@onready var floor_detector: RayCast2D = get_node_or_null("EnemyStateMachine/FloorDetector")

# Debug label showing current state and health.
@onready var state_label: Label = $StateLabel

# Hitbox used when attacking.
@onready var attack_area: AttackArea = $AttackArea

# Area used to receive damage.
@onready var damageable_area: DamageableArea = $DamageableArea



#TUNABLE STATS

# Horizontal movement speed when chasing player.
@export var speed_run: float = 140.0

# Downward force applied every frame.
@export var gravity: float = 600.0

# Distance required to start attacking.
@export var attack_distance: float = 40.0

# Distance required to start chasing.
@export var run_distance: float = 220.0

# Maximum health before death.
@export var max_health: float = 3.0

# Damage dealt per attack.
@export var damage: float = 1.0

# How long the attack hitbox stays active.
@export var attack_duration: float = 0.12

# Delay between consecutive attacks.
@export var attack_cooldown: float = 0.45

# Force applied when taking damage.
@export var knockback_force: float = 120.0



#RUNTIME STATE

# Current health value.
var health: float = 0.0

# Current active state.
var current_state: State = State.IDLE

# Reference to detected player.
var player: Node2D = null

# Direction the enemy is facing (-1 left, 1 right).
var facing_dir: int = 1

# True while attack animation is playing.
var attack_playing: bool = false

# Prevents immediate repeated attacks.
var attack_on_cooldown: bool = false

# True while taking damage animation is playing.
var hurt_playing: bool = false

# True once enemy is dead.
var dead: bool = false

# Random generator for attack variation.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()



#LIFECYCLE

func _ready() -> void:

	# Initialize random generator and health.
	rng.randomize()
	health = max_health

	# Connect signals for detection and animation.
	player_detector.body_entered.connect(_on_player_entered)
	player_detector.body_exited.connect(_on_player_exited)
	sprite.animation_finished.connect(_on_animation_finished)
	damageable_area.damage_taken.connect(_on_damage_taken)

	# Setup attack hitbox.
	if attack_area != null:
		attack_area.damage = damage
		attack_area.set_active(false)



#PHYSICS UPDATE

func _physics_process(delta: float) -> void:

	# Apply gravity and update behavior.
	apply_gravity(delta)
	update_facing()
	update_state()

	# Run behavior based on current state.
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

	# Update debug info.
	update_label()



#MOVEMENT

# Applies downward force when not grounded.
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0



#FACING

# Updates direction based on player position.
func update_facing() -> void:

	if player != null and is_instance_valid(player) and not dead:

		var dir_x: float = sign(player.global_position.x - global_position.x)

		# Only update if there is a clear direction.
		if dir_x != 0.0:
			facing_dir = int(dir_x)

	# Flip sprite visually.
	sprite.flip_h = facing_dir < 0

	# Flip attack hitbox.
	if attack_area != null:
		attack_area.flip(float(facing_dir))



#STATE LOGIC

# Determines which state the enemy should be in.
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

	# Choose behavior based on distance.
	if dist <= attack_distance and not attack_on_cooldown:
		current_state = State.ATTACK
	elif dist <= run_distance:
		current_state = State.RUN
	else:
		current_state = State.IDLE



#STATE HANDLERS

func handle_idle() -> void:

	# Stop movement.
	velocity.x = 0.0

	# Play idle animation.
	if sprite.animation != "Idle":
		sprite.play("Idle")


func handle_run() -> void:

	# Move toward player.
	velocity.x = float(facing_dir) * speed_run

	update_floor_ray()

	# Stop if no ground ahead.
	if floor_detector != null and not floor_detector.is_colliding():
		velocity.x = 0.0

	if sprite.animation != "Run":
		sprite.play("Run")


func handle_attack() -> void:

	# Stop moving while attacking.
	velocity.x = 0.0

	if not attack_playing:
		start_attack()


func handle_take_damage() -> void:

	# Gradually slow down knockback.
	velocity.x = move_toward(velocity.x, 0.0, 25.0)

	if sprite.animation != "Take_Damage":
		sprite.play("Take_Damage")


func handle_death() -> void:

	# Stop all movement.
	velocity.x = 0.0

	if sprite.animation != "Death":
		sprite.play("Death")



#ATTACK

# Starts attack animation and activates hitbox.
func start_attack() -> void:

	attack_playing = true
	attack_on_cooldown = true

	if attack_area != null:
		attack_area.damage = damage

	# Randomize attack animation for variation.
	var attack_anim: String = "Attack_" + str(rng.randi_range(1, 3))
	sprite.play(attack_anim)

	_do_attack_hit()


# Activates hitbox for a short duration.
func _do_attack_hit() -> void:

	if attack_area == null:
		return

	attack_area.flip(float(facing_dir))
	attack_area.activate(attack_duration)



#ENVIRONMENT CHECK

# Updates raycast direction based on facing.
func update_floor_ray() -> void:

	if floor_detector != null:
		floor_detector.target_position.x = absf(floor_detector.target_position.x) * float(facing_dir)



#ANIMATION EVENTS

func _on_animation_finished() -> void:

	# Attack finished → start cooldown.
	if sprite.animation.begins_with("Attack_"):
		attack_playing = false
		_start_attack_cooldown()

	# Damage animation finished → remove invulnerability.
	elif sprite.animation == "Take_Damage":
		hurt_playing = false
		if damageable_area != null:
			damageable_area.end_invulnerable()

	# Death animation finished → remove enemy.
	elif sprite.animation == "Death":
		await get_tree().create_timer(1.0).timeout
		queue_free()



# Starts cooldown timer after attack.
func _start_attack_cooldown() -> void:

	await get_tree().create_timer(attack_cooldown).timeout
	attack_on_cooldown = false



#DAMAGE

# Handles incoming damage from attack areas.
func _on_damage_taken(attack_area_source: AttackArea) -> void:

	if dead:
		return

	if hurt_playing:
		return

	# Reduce health.
	health -= attack_area_source.damage
	print("Enemy health: ", health)

	# Check for death.
	if health <= 0.0:
		die()
		return

	hurt_playing = true

	# Enable temporary invulnerability.
	if damageable_area != null:
		damageable_area.start_invulnerable()

	# Apply knockback away from source.
	var source_pos: Vector2 = attack_area_source.global_position
	var knockback_dir: float = sign(global_position.x - source_pos.x)

	# Fallback if perfectly aligned.
	if knockback_dir == 0.0:
		knockback_dir = -float(facing_dir)

	velocity.x = knockback_dir * knockback_force

	sprite.play("Take_Damage")



#DEATH

# Handles full death logic.
func die() -> void:

	if dead:
		return

	dead = true
	hurt_playing = false
	attack_playing = false
	attack_on_cooldown = true
	current_state = State.DEATH

	velocity = Vector2.ZERO

	# Disable attack hitbox.
	if attack_area != null:
		attack_area.set_active(false)

	# Stop detecting player.
	if player_detector != null:
		player_detector.monitoring = false

	# Disable damage reception.
	if damageable_area != null:
		damageable_area.start_invulnerable()
		damageable_area.monitoring = false

	sprite.play("Death")



#DEBUG

# Displays current state and health.
func update_label() -> void:

	if state_label != null:
		state_label.text = State.keys()[current_state] + " | HP: " + str(health)



#PLAYER DETECTION

func _on_player_entered(body: Node) -> void:

	if dead:
		return

	if body.is_in_group("Player"):
		player = body as Node2D


func _on_player_exited(body: Node) -> void:

	if body == player:
		player = null
