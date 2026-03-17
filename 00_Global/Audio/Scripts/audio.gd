extends Node
# Audio global script.
# Handles music playback, UI sounds, reverb, spatial SFX, and heartbeat loops

enum REVERB_TYPE { NONE, SMALL, MEDIUM, LARGE }

# UI audio exports
@export var ui_focus_audio: AudioStream
@export var ui_select_audio: AudioStream
@export var ui_cancel_audio: AudioStream
@export var ui_success_audio: AudioStream
@export var ui_error_audio: AudioStream

# Heartbeat exports
# Heartbeat button helpers
@export var heartbeat_01: AudioStream
@export var heartbeat_02: AudioStream
@export var heartbeat_03: AudioStream

# Heartbeat nodes
@onready var heartbeat: AudioStreamPlayer = %Heartbeat

# Music
var current_track: int = 0
var music_tweens: Array[Tween] = []

@onready var music_1: AudioStreamPlayer = %Music1
@onready var music_2: AudioStreamPlayer = %Music2
@onready var ui: AudioStreamPlayer = %UI
var ui_audio_player: AudioStreamPlaybackPolyphonic

# Heartbeat state
var current_heartbeat: int = -1

#region Heartbeat functions
# Plays the selected heartbeat stage (0, 1, 2)
func play_heartbeat_loop(stage: int) -> void:
	if current_heartbeat == stage:
		return

	current_heartbeat = stage
	match stage:
		0:
			if heartbeat_01:
				heartbeat.stream = heartbeat_01
		1:
			if heartbeat_02:
				heartbeat.stream = heartbeat_02
		2:
			if heartbeat_03:
				heartbeat.stream = heartbeat_03

	if heartbeat:
		heartbeat.stop()
		heartbeat.play()

# Stops all heartbeat sounds immediately
func stop_heartbeat() -> void:
	if heartbeat:
		heartbeat.stop()
	current_heartbeat = -1
#endregion

func _ready() -> void:
	# Prepare ui_audio_player
	if ui:
		ui_audio_player = ui.get_stream_playback()
	pass

# Plays music with crossfade
func play_music(audio: AudioStream) -> void:
	var current_player: AudioStreamPlayer = get_music_player(current_track)
	if current_player.stream == audio:
		return

	var next_track: int = (current_track + 1) % 2
	var next_player: AudioStreamPlayer = get_music_player(next_track)

	next_player.stream = audio
	next_player.play()

	for t in music_tweens:
		t.kill()
	music_tweens.clear()

	fade_track_out(current_player)
	fade_track_in(next_player)

	current_track = next_track

# Returns the music player based on index
func get_music_player(i: int) -> AudioStreamPlayer:
	return music_1 if i == 0 else music_2

# Fades out a track
func fade_track_out(player: AudioStreamPlayer) -> void:
	var tween: Tween = create_tween()
	music_tweens.append(tween)
	tween.tween_property(player, "volume_linear", 0.0, 1.5)
	tween.tween_callback(player.stop)

# Fades in a track
func fade_track_in(player: AudioStreamPlayer) -> void:
	var tween: Tween = create_tween()
	music_tweens.append(tween)
	tween.tween_property(player, "volume_linear", 1.0, 1.0)

# Sets reverb based on type
func set_reverb(type: REVERB_TYPE) -> void:
	var reverb_fx: AudioEffectReverb = AudioServer.get_bus_effect(1, 0)
	if not reverb_fx:
		return
	AudioServer.set_bus_effect_enabled(1, 0, true)
	match type:
		REVERB_TYPE.NONE:
			AudioServer.set_bus_effect_enabled(1, 0, false)
		REVERB_TYPE.SMALL:
			reverb_fx.room_size = 0.2
		REVERB_TYPE.MEDIUM:
			reverb_fx.room_size = 0.5
		REVERB_TYPE.LARGE:
			reverb_fx.room_size = 0.8

# Plays spatial sound at position
func play_spatial_sound(audio: AudioStream, pos: Vector2) -> void:
	var audio_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.bus = "SFX"
	audio_player.global_position = pos
	audio_player.stream = audio
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.play()

# Plays UI sound
func play_ui_audio(audio: AudioStream) -> void:
	if ui_audio_player:
		ui_audio_player.play_stream(audio)

# Setup button audio helpers
func setup_button_audio(node: Node) -> void:
	for c in node.find_children("*", "Button"):
		c.pressed.connect(ui_select)
		c.focus_entered.connect(ui_focus_change)

#region UI audio playback
func ui_focus_change() -> void:
	play_ui_audio(ui_focus_audio)

func ui_select() -> void:
	play_ui_audio(ui_select_audio)

func ui_cancel() -> void:
	play_ui_audio(ui_cancel_audio)

func ui_success() -> void:
	play_ui_audio(ui_success_audio)

func ui_error() -> void:
	play_ui_audio(ui_error_audio)
#endregion
