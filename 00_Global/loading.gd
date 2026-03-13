extends CanvasLayer

@onready var black_rect: ColorRect = $BlackRect
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@export var load_time: float = 1.5 # seconds to show "loading"
@export var static_audio_stream: AudioStream = preload("uid://brf2ppngqgpin")
@export var static_extra_time: float = 0.5 # how long static continues after fade

var static_player: AudioStreamPlayer

func _start(slot: int, is_new_game: bool) -> void:
	black_rect.visible = true
	black_rect.modulate.a = 0.0

	# Fade in black
	var tween = create_tween()
	tween.tween_property(black_rect, "modulate:a", 1.0, 0.3)
	await tween.finished

	# Play loading animation
	if anim_player:
		anim_player.play("spin")

	# Play static sound
	static_player = AudioStreamPlayer.new()
	add_child(static_player)
	static_player.stream = static_audio_stream
	static_player.volume_db = 0.0
	static_player.play()

	# Wait load_time seconds
	await get_tree().create_timer(load_time).timeout

	# Load the selected game scene
	if slot >= 0:
		SaveManager.current_slot = slot
		if is_new_game:
			SaveManager.create_new_game_save(slot)
		else:
			await SaveManager.load_game()  # make load_game async

	# Fade out black
	var fade_out = create_tween()
	fade_out.tween_property(black_rect, "modulate:a", 0.0, 0.3)
	await fade_out.finished

	# Keep static playing for extra time
	await get_tree().create_timer(static_extra_time).timeout

	# Stop static smoothly
	if static_player:
		var fade_static = create_tween()
		fade_static.tween_property(static_player, "volume_db", -80.0, 0.5)
		await fade_static.finished
		static_player.stop()
		static_player.queue_free()

	queue_free()
