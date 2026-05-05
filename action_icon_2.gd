extends Control

@onready var unpressed_icon: TextureRect = $UnpressedIcon
@onready var pressed_icon: TextureRect = $PressedIcon
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func set_button(action_name: String, mode: int) -> void:
	unpressed_icon.texture = InputIconLibrary.get_unpressed_icon(action_name)
	pressed_icon.texture = InputIconLibrary.get_pressed_icon(action_name)

	match mode:
		0:
			animation_player.play("idle")
		1:
			animation_player.play("tap")
		2:
			animation_player.play("hold")
#1
