extends Control

@onready var master_slider: HSlider = $VBoxContainer/MasterSilder
@onready var music_slider: HSlider = $VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SFXSlider

@onready var master_label: Label = $VBoxContainer/MasterVol
@onready var music_label: Label = $VBoxContainer/MusicVol
@onready var sfx_label: Label = $VBoxContainer/SFXVol

func _ready() -> void:
	setup_sliders()
	load_values_from_audio()

	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	update_labels()

func setup_sliders() -> void:
	for slider in [master_slider, music_slider, sfx_slider]:
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 1.0
		slider.focus_mode = Control.FOCUS_ALL

func load_values_from_audio() -> void:
	master_slider.value = Audio.get_master_volume() * 100.0
	music_slider.value = Audio.get_music_volume() * 100.0
	sfx_slider.value = Audio.get_sfx_volume() * 100.0

func _on_master_slider_changed(value: float) -> void:
	Audio.set_master_volume(value / 100.0, true)
	update_labels()

func _on_music_slider_changed(value: float) -> void:
	Audio.set_music_volume(value / 100.0, true)
	update_labels()

func _on_sfx_slider_changed(value: float) -> void:
	Audio.set_sfx_volume(value / 100.0, true)
	update_labels()
	Audio.ui_focus_change()

func update_labels() -> void:
	master_label.text = "Master Volume: %d%%" % int(round(master_slider.value))
	music_label.text = "Music Volume: %d%%" % int(round(music_slider.value))
	sfx_label.text = "SFX Volume: %d%%" % int(round(sfx_slider.value))
