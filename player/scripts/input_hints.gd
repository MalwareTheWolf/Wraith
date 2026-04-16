@icon("res://General/Icon/input_hints.svg")
class_name InputHints
extends Node2D

const CONTROLLER_FRAME_MAP: Dictionary = {
	"playstation": {
		"buttons": {
			JOY_BUTTON_A: 1,
			JOY_BUTTON_B: 3,
			JOY_BUTTON_X: 2,
			JOY_BUTTON_Y: 0,
			JOY_BUTTON_DPAD_UP: 4
		}
	},
	"xbox": {
		"buttons": {
			JOY_BUTTON_A: 5,
			JOY_BUTTON_B: 6,
			JOY_BUTTON_X: 7,
			JOY_BUTTON_Y: 8,
			JOY_BUTTON_DPAD_UP: 4
		}
	},
	"switch": {
		"buttons": {
			JOY_BUTTON_A: 18,
			JOY_BUTTON_B: 17,
			JOY_BUTTON_X: 19,
			JOY_BUTTON_Y: 20,
			JOY_BUTTON_DPAD_UP: 4
		}
	}
}

var controller_type: String = "keyboard"
var current_hint: StringName = &""

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hint_label: Label = get_node_or_null("HintLabel")

func _ready() -> void:
	visible = false

	if Messages.input_hint_changed.is_connected(_on_hint_changed) == false:
		Messages.input_hint_changed.connect(_on_hint_changed)

	_update_device_from_input_settings()
	_refresh_hint()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey:
		controller_type = "keyboard"
		_refresh_hint()
	elif event is InputEventJoypadButton:
		_set_controller_type_from_device(event.device)
		_refresh_hint()
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		_set_controller_type_from_device(event.device)
		_refresh_hint()

func _update_device_from_input_settings() -> void:
	if InputSettings.current_device == InputSettings.InputDevice.KEYBOARD_MOUSE:
		controller_type = "keyboard"
	else:
		var joypads: PackedInt32Array = Input.get_connected_joypads()
		if joypads.size() > 0:
			_set_controller_type_from_device(joypads[0])
		else:
			controller_type = "playstation"

func _set_controller_type_from_device(device_id: int) -> void:
	var n: String = Input.get_joy_name(device_id).to_lower()

	if "xbox" in n:
		controller_type = "xbox"
	elif "nintendo" in n or "switch" in n:
		controller_type = "switch"
	else:
		controller_type = "playstation"

func _on_hint_changed(hint: String) -> void:
	current_hint = StringName(hint)

	if hint == "":
		visible = false
		return

	visible = true
	_update_device_from_input_settings()
	_refresh_hint()

func _refresh_hint() -> void:
	if current_hint == &"":
		visible = false
		return

	var event: InputEvent = _get_primary_binding(current_hint)

	if event == null:
		_show_text("?")
		return

	if event is InputEventKey or event is InputEventMouseButton:
		_show_text(_short_text(InputSettings.event_to_text(event)))
		return

	if event is InputEventJoypadButton:
		_show_controller_button(event as InputEventJoypadButton)
		return

	if event is InputEventJoypadMotion:
		_show_controller_motion(event as InputEventJoypadMotion)
		return

	_show_text("?")

func _get_primary_binding(action: StringName) -> InputEvent:
	if not InputMap.has_action(action):
		return null

	var visible_bindings: Array[InputEvent] = InputSettings.get_bindings(action)
	if visible_bindings.is_empty():
		return null

	return visible_bindings[0]

func _show_text(text: String) -> void:
	sprite_2d.visible = false
	if hint_label:
		hint_label.visible = true
		hint_label.text = text

func _show_controller_button(event: InputEventJoypadButton) -> void:
	var family_map: Dictionary = CONTROLLER_FRAME_MAP.get(controller_type, {})
	var button_map: Dictionary = family_map.get("buttons", {})

	if button_map.has(event.button_index):
		sprite_2d.visible = true
		if hint_label:
			hint_label.visible = false
		sprite_2d.frame = int(button_map[event.button_index])
	else:
		_show_text("Pad %d" % event.button_index)

func _show_controller_motion(event: InputEventJoypadMotion) -> void:
	var dir_text: String = "+" if event.axis_value > 0.0 else "-"
	_show_text("Axis %d %s" % [event.axis, dir_text])

func _short_text(text: String) -> String:
	match text:
		"Mouse Left":
			return "LMB"
		"Mouse Right":
			return "RMB"
		"Mouse Middle":
			return "MMB"
		"Mouse Button 4":
			return "M4"
		"Mouse Button 5":
			return "M5"
		"Wheel Up":
			return "Wh+"
		"Wheel Down":
			return "Wh-"
		"Up":
			return "↑"
		"Down":
			return "↓"
		"Left":
			return "←"
		"Right":
			return "→"
		_:
			return text
