extends CharacterBody2D

# --- Nodes ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_detector: Area2D = $PlayerDetector
@onready var floor_detector: RayCast2D = $FloorDetector
@onready var state_label: Label = $StateLabel

# --- Enemy stats ---
@export var speed_run: float = 120
@export var speed_walk: float = 60
@export var gravity: float = 600
@export var attack_distance: float = 30
@export var walk_distance: float = 100
@export var run_distance: float = 200

# --- Internal state ---
var player: Node = null
var current_state: String = "IDLE"
var attack_playing: bool = false

var rng := RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	if player_detector:
		if not player_detector.is_connected("body_entered", Callable(self, "_on_player_entered")):
			player_detector.body_entered.connect(Callable(self, "_on_player_entered"))
		if not player_detector.is_connected("body_exited", Callable(self, "_on_player_exited")):
			player_detector.body_exited.connect(Callable(self, "_on_player_exited"))
	pass

func _physics_process(delta):
	_handle_gravity(delta)
	_update_state()
	_handle_movement(delta)
	_update_animation()
	_update_label()
	pass

# --- Gravity ---
func _handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	pass

# --- State updates ---
func _update_state():
	if not player or not is_instance_valid(player):
		current_state = "IDLE"
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= attack_distance:
		current_state = "ATTACK"
	elif distance <= walk_distance:
		current_state = "WALK"
	elif distance <= run_distance:
		current_state = "RUN"
	else:
		current_state = "IDLE"
	pass

# --- Movement ---
func _handle_movement(delta):
	velocity.x = 0

	if not player or not is_instance_valid(player):
		move_and_slide()
		return

	var direction = (player.global_position - global_position).normalized()
	
	match current_state:
		"RUN":
			velocity.x = direction.x * speed_run
		"WALK":
			velocity.x = direction.x * speed_walk
		"ATTACK", "IDLE":
			velocity.x = 0

	# Prevent walking off edges
	if velocity.x != 0 and not floor_detector.is_colliding():
		velocity.x = 0

	# Flip sprite based on movement
	if sprite:
		sprite.flip_h = velocity.x < 0

	move_and_slide()
	pass

# --- Animation ---
func _update_animation():
	if not sprite:
		return

	match current_state:
		"IDLE":
			sprite.play("Idle")
		"WALK":
			sprite.play("Walk")
		"RUN":
			sprite.play("Run")
		"ATTACK":
			if not attack_playing:
				var attack_anim = "Attack_" + str(rng.randi_range(1, 3))
				sprite.play(attack_anim)
				attack_playing = true
				sprite.animation_finished.connect(Callable(self, "_on_attack_finished"))
	pass

func _on_attack_finished():
	attack_playing = false
	pass

# --- Label ---
func _update_label():
	if state_label:
		state_label.text = str(current_state)
	pass

# --- Player detection callbacks ---
func _on_player_entered(body):
	if body.is_in_group("Player"):
		player = body
	pass

func _on_player_exited(body):
	if body == player:
		player = null
	pass
