extends Area2D

enum CutsceneMode {
	RUN_AWAY,
	AUDIO_ONLY,
	ATTACK_AND_EXIT
}

enum ActorChoice {
	ACTOR,
	SECONDARY_ACTOR
}

@export var cutscene_id: String = "cutscene_test"
@export var cutscene_mode: CutsceneMode = CutsceneMode.RUN_AWAY

@export var actor: Node2D
@export var secondary_actor: Node2D

@export var camera_target: ActorChoice = ActorChoice.ACTOR
@export var exit_actor: ActorChoice = ActorChoice.ACTOR

@export var actor_speed: float = 120.0
@export var secondary_actor_speed: float = 90.0

@export var idle_animation_name: String = "idle"
@export var run_animation_name: String = "run"
@export var death_animation_name: String = "death"
@export var attack_animation_name: String = "holy_slash"
@export var walk_animation_name: String = "run"

@export var idle_time_before_run: float = 0.5
@export var camera_focus_time: float = 0.75
@export var actor_follow_time: float = 1.5
@export var camera_hold_after_follow_time: float = 1.0
@export var camera_return_time: float = 0.75

@export var flip_actor_before_death: bool = false
@export var flip_secondary_before_attack: bool = false
@export var flip_secondary_after_attack: bool = true
@export var flip_exit_actor_while_moving: bool = true
@export var invert_exit_flip: bool = true

@export var secondary_attack_y_offset: float = 0.0

@export var disappear_at_end: bool = true
@export var trigger_once: bool = true

@export var skip_action: String = "jump"
@export var allow_skip: bool = false

@export var run_audio: AudioStream
@export var death_audio: AudioStream
@export var play_audio_when_run_starts: bool = true
@export var audio_bus: String = "SFX"

@onready var end_marker: Marker2D = $EndMarker

var player: Player
var camera: Camera2D
var audio_player: AudioStreamPlayer2D

var has_triggered: bool = false
var cutscene_active: bool = false
var skip_requested: bool = false

var moving_node: Node2D
var moving_speed: float = 0.0
var actor_running: bool = false
var actor_reached_end: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)

	body_entered.connect(_on_body_entered)

	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.bus = audio_bus

	_cleanup_if_already_played()


func _cleanup_if_already_played() -> void:
	var flag_id := "cutscene_" + cutscene_id

	if not SaveManager.has_flag(flag_id):
		return

	has_triggered = true
	cutscene_active = false
	actor_running = false
	monitoring = false

	if actor:
		actor.queue_free()

	if secondary_actor:
		secondary_actor.queue_free()


func _input(event: InputEvent) -> void:
	if not cutscene_active:
		return

	if not allow_skip:
		return

	if event.is_action_pressed(skip_action):
		skip_requested = true


func _physics_process(delta: float) -> void:
	if not actor_running or moving_node == null:
		return

	var target_position := end_marker.global_position
	var direction := moving_node.global_position.direction_to(target_position)

	moving_node.global_position += direction * moving_speed * delta

	if flip_exit_actor_while_moving:
		_flip_sprite_to_direction(moving_node, direction)

	if moving_node.global_position.distance_to(target_position) <= 5.0:
		moving_node.global_position = target_position
		actor_running = false
		actor_reached_end = true


func _on_body_entered(body: Node) -> void:
	if trigger_once and has_triggered:
		return

	if not body.is_in_group("Player"):
		return

	var flag_id := "cutscene_" + cutscene_id

	if SaveManager.has_flag(flag_id):
		_cleanup_if_already_played()
		return

	has_triggered = true
	SaveManager.set_flag(flag_id, true)

	match cutscene_mode:
		CutsceneMode.AUDIO_ONLY:
			play_audio(run_audio, global_position)

			if trigger_once:
				monitoring = false

		CutsceneMode.RUN_AWAY:
			start_run_away_sequence()

		CutsceneMode.ATTACK_AND_EXIT:
			start_attack_and_exit_sequence()


func _setup_player_and_camera() -> bool:
	player = get_tree().get_first_node_in_group("Player") as Player

	if player != null:
		camera = player.get_node_or_null("Camera2D") as Camera2D

	if player == null or camera == null:
		push_warning("CinematicTrigger missing player or camera.")
		return false

	return true


func _begin_cutscene() -> bool:
	if not _setup_player_and_camera():
		return false

	cutscene_active = true
	skip_requested = false

	await _wait_for_player_to_land()

	player.set_control_enabled(false)

	return true


func _wait_for_player_to_land() -> void:
	if player == null:
		return

	while player is CharacterBody2D and not player.is_on_floor():
		await get_tree().physics_frame


func _end_cutscene() -> void:
	actor_running = false
	cutscene_active = false
	skip_requested = false

	if player:
		player.set_control_enabled(true)

	if trigger_once:
		monitoring = false


func start_run_away_sequence() -> void:
	if actor == null:
		push_warning("RUN_AWAY needs Actor.")
		return

	if not await _begin_cutscene():
		return

	await _move_camera_to(actor.global_position, camera_focus_time)

	if skip_requested:
		await _skip_finish()
		return

	await _play_idle_then_run(actor)

	actor_reached_end = false
	moving_node = actor
	moving_speed = actor_speed
	actor_running = true

	if play_audio_when_run_starts:
		play_audio(run_audio, actor.global_position)

	await _follow_node_for_time(actor, actor_follow_time)
	await _wait_seconds(camera_hold_after_follow_time)
	await _wait_for_actor_to_reach_end()

	if disappear_at_end and actor:
		actor.visible = false

	await _move_camera_to(player.global_position, camera_return_time)

	_end_cutscene()


func start_attack_and_exit_sequence() -> void:
	if actor == null or secondary_actor == null:
		push_warning("ATTACK_AND_EXIT needs Actor and Secondary Actor.")
		return

	if not await _begin_cutscene():
		return

	var focus_node := _get_actor_choice(camera_target)
	var exiting_node := _get_actor_choice(exit_actor)

	if focus_node == null or exiting_node == null:
		push_warning("Invalid camera target or exit actor.")
		_end_cutscene()
		return

	await _move_camera_to(focus_node.global_position, camera_focus_time)

	if skip_requested:
		await _skip_finish()
		return

	if flip_secondary_before_attack:
		_flip_sprite(secondary_actor)

	if flip_actor_before_death:
		_flip_sprite(actor)

	_set_sprite_y_offset(secondary_actor, secondary_attack_y_offset)

	await _play_animation(secondary_actor, attack_animation_name)

	if skip_requested:
		await _skip_finish()
		return

	if flip_secondary_after_attack:
		_flip_sprite(secondary_actor)

	await _play_animation(actor, death_animation_name)

	if skip_requested:
		await _skip_finish()
		return

	play_audio(death_audio, actor.global_position)

	actor_reached_end = false
	moving_node = exiting_node
	moving_speed = secondary_actor_speed if exiting_node == secondary_actor else actor_speed

	_play_animation_no_wait(exiting_node, walk_animation_name)
	_set_sprite_y_offset(secondary_actor, 0.0)

	actor_running = true

	await _follow_node_for_time(exiting_node, actor_follow_time)
	await _wait_seconds(camera_hold_after_follow_time)
	await _wait_for_actor_to_reach_end()

	if disappear_at_end and exiting_node:
		exiting_node.visible = false

	await _move_camera_to(player.global_position, camera_return_time)

	_end_cutscene()


func _skip_finish() -> void:
	actor_running = false

	if actor:
		_set_sprite_y_offset(actor, 0.0)

	if secondary_actor:
		_set_sprite_y_offset(secondary_actor, 0.0)

	if camera and player:
		camera.global_position = player.global_position

	_end_cutscene()


func _get_actor_choice(choice: ActorChoice) -> Node2D:
	match choice:
		ActorChoice.ACTOR:
			return actor
		ActorChoice.SECONDARY_ACTOR:
			return secondary_actor

	return null


func _play_idle_then_run(target: Node2D) -> void:
	_play_animation_no_wait(target, idle_animation_name)

	await _wait_seconds(idle_time_before_run)

	if skip_requested:
		return

	_play_animation_no_wait(target, run_animation_name)


func _play_animation(target: Node2D, animation_name: String) -> void:
	if target == null:
		return

	var anim_player := target.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player and anim_player.has_animation(animation_name):
		anim_player.play(animation_name)

		while anim_player.is_playing():
			if skip_requested:
				return
			await get_tree().process_frame

		return

	var animated_sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)

		while animated_sprite.is_playing():
			if skip_requested:
				return
			await get_tree().process_frame

		return


func _play_animation_no_wait(target: Node2D, animation_name: String) -> void:
	if target == null:
		return

	var anim_player := target.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player and anim_player.has_animation(animation_name):
		anim_player.play(animation_name)
		return

	var animated_sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
		return


func _move_camera_to(target_position: Vector2, duration: float) -> void:
	if camera == null:
		return

	var tween := create_tween()
	tween.tween_property(camera, "global_position", target_position, duration)

	while tween.is_running():
		if skip_requested:
			tween.kill()
			return
		await get_tree().process_frame


func _follow_node_for_time(target: Node2D, duration: float) -> void:
	var timer := 0.0

	while timer < duration and target != null:
		if skip_requested:
			return

		camera.global_position = target.global_position
		timer += get_process_delta_time()
		await get_tree().process_frame


func _wait_seconds(duration: float) -> void:
	var timer := 0.0

	while timer < duration:
		if skip_requested:
			return

		timer += get_process_delta_time()
		await get_tree().process_frame


func _wait_for_actor_to_reach_end() -> void:
	while not actor_reached_end:
		if skip_requested:
			return

		await get_tree().process_frame


func _flip_sprite(target: Node2D) -> void:
	if target == null:
		return

	var sprite := target.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.flip_h = not sprite.flip_h
		return

	var animated_sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite:
		animated_sprite.flip_h = not animated_sprite.flip_h


func _flip_sprite_to_direction(target: Node2D, direction: Vector2) -> void:
	if target == null or direction.x == 0.0:
		return

	var should_flip := direction.x > 0.0

	if invert_exit_flip:
		should_flip = not should_flip

	var sprite := target.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.flip_h = should_flip
		return

	var animated_sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite:
		animated_sprite.flip_h = should_flip


func _set_sprite_y_offset(target: Node2D, offset: float) -> void:
	if target == null:
		return

	var sprite := target.get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.position.y = offset
		return

	var animated_sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite:
		animated_sprite.position.y = offset


func play_audio(stream: AudioStream, at_position: Vector2) -> void:
	if stream == null:
		return

	audio_player.stream = stream
	audio_player.global_position = at_position
	audio_player.play()
