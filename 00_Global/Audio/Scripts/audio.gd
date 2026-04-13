extends Node
# Audio global script.
# Handles music playback, UI sounds, reverb, spatial SFX, heartbeat loops,
# and persistent audio settings.

enum REVERB_TYPE { NONE, SMALL, MEDIUM, LARGE }

const SETTINGS_PATH := "user://settings.cfg"

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_UI := "UI"
const BUS_HEARTBEAT := "Heartbeat"

# UI audio exports
@export var ui_focus_audio: AudioStream
@export var ui_select_audio: AudioStream
@export var ui_cancel_audio: AudioStream
@export var ui_success_audio: AudioStream
@export var ui_error_audio: AudioStream

# Heartbeat exports
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

# Stored as normalized values from 0.0 to 1.0
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

#region Startup
func _ready() -> void:
	if ui:
		ui_audio_player = ui.get_stream_playback()

	load_audio_settings()
	apply_all_audio_settings()
#endregion

#region Save / Load
func save_audio_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)

	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("Failed to save audio settings. Error code: %s" % err)

func load_audio_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)

	if err != OK:
		master_volume = 1.0
		music_volume = 1.0
		sfx_volume = 1.0
		return

	master_volume = clamp(float(config.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)
	music_volume = clamp(float(config.get_value("audio", "music_volume", 1.0)), 0.0, 1.0)
	sfx_volume = clamp(float(config.get_value("audio", "sfx_volume", 1.0)), 0.0, 1.0)
#endregion

#region Volume API
func apply_all_audio_settings() -> void:
	set_bus_volume_linear(BUS_MASTER, master_volume)
	set_bus_volume_linear(BUS_MUSIC, music_volume)
	set_bus_volume_linear(BUS_SFX, sfx_volume)
	set_bus_volume_linear(BUS_UI, sfx_volume)
	set_bus_volume_linear(BUS_HEARTBEAT, sfx_volume)

func set_master_volume(value: float, save: bool = true) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	set_bus_volume_linear(BUS_MASTER, master_volume)
	if save:
		save_audio_settings()

func set_music_volume(value: float, save: bool = true) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	set_bus_volume_linear(BUS_MUSIC, music_volume)
	if save:
		save_audio_settings()

func set_sfx_volume(value: float, save: bool = true) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	set_bus_volume_linear(BUS_SFX, sfx_volume)
	set_bus_volume_linear(BUS_UI, sfx_volume)
	set_bus_volume_linear(BUS_HEARTBEAT, sfx_volume)
	if save:
		save_audio_settings()

func get_master_volume() -> float:
	return master_volume

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

func set_bus_volume_linear(bus_name: String, linear_value: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_warning("Audio bus not found: %s" % bus_name)
		return

	linear_value = clamp(linear_value, 0.0, 1.0)

	if linear_value <= 0.001:
		AudioServer.set_bus_volume_db(bus_idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_value))

func get_bus_volume_linear(bus_name: String) -> float:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return 1.0

	var db := AudioServer.get_bus_volume_db(bus_idx)
	if db <= -79.0:
		return 0.0

	return db_to_linear(db)
#endregion

#region Heartbeat functions
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

func stop_heartbeat() -> void:
	if heartbeat:
		heartbeat.stop()
	current_heartbeat = -1
#endregion

#region Music
func play_music(audio: AudioStream) -> void:
	var current_player: AudioStreamPlayer = get_music_player(current_track)
	if current_player.stream == audio:
		return

	var next_track: int = (current_track + 1) % 2
	var next_player: AudioStreamPlayer = get_music_player(next_track)

	next_player.stream = audio
	next_player.volume_linear = 0.0
	next_player.play()

	for t in music_tweens:
		t.kill()
	music_tweens.clear()

	fade_track_out(current_player)
	fade_track_in(next_player)

	current_track = next_track

func get_music_player(i: int) -> AudioStreamPlayer:
	return music_1 if i == 0 else music_2

func fade_track_out(player: AudioStreamPlayer) -> void:
	var tween: Tween = create_tween()
	music_tweens.append(tween)
	tween.tween_property(player, "volume_linear", 0.0, 1.5)
	tween.tween_callback(player.stop)

func fade_track_in(player: AudioStreamPlayer) -> void:
	var tween: Tween = create_tween()
	music_tweens.append(tween)
	tween.tween_property(player, "volume_linear", 1.0, 1.0)
#endregion

#region Reverb
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
#endregion

#region Sound playback
func play_spatial_sound(audio: AudioStream, pos: Vector2) -> void:
	var audio_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.bus = BUS_SFX
	audio_player.global_position = pos
	audio_player.stream = audio
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.play()

func play_ui_audio(audio: AudioStream) -> void:
	if ui_audio_player and audio:
		ui_audio_player.play_stream(audio)
#endregion

#region Button helpers
func setup_button_audio(node: Node) -> void:
	for c in node.find_children("*", "Button"):
		c.pressed.connect(ui_select)
		c.focus_entered.connect(ui_focus_change)
#endregion

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
