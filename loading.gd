extends CanvasLayer

@onready var black_rect: ColorRect = $BlackRect
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Adjustable loading time
var load_time: float = 1.5  # seconds

# Called by TitleScreen.gd
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

	# Wait adjustable time
	await get_tree().create_timer(load_time).timeout

	# Load or create game save AFTER fade-in and wait
	if slot >= 0:
		SaveManager.current_slot = slot
		if is_new_game:
			await SaveManager.create_new_game_save(slot)
		await SaveManager.load_game()

	# Fade out black
	var fade_out = create_tween()
	fade_out.tween_property(black_rect, "modulate:a", 0.0, 0.3)
	await fade_out.finished

	queue_free()
