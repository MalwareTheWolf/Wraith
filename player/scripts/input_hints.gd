extends Node2D

@export var icon_sheet: Texture2D

@onready var icon_sprite: Sprite2D = $Sprite2D

const HFRAMES: int = 34
const VFRAMES: int = 24

var current_prompt: String = ""

func _ready() -> void:
	visible = false

	if icon_sprite:
		if icon_sheet:
			icon_sprite.texture = icon_sheet
		icon_sprite.hframes = HFRAMES
		icon_sprite.vframes = VFRAMES
		icon_sprite.frame = 0

	if Messages.input_hint_changed.is_connected(_on_input_hint_changed) == false:
		Messages.input_hint_changed.connect(_on_input_hint_changed)

	if InputSettings.bindings_changed.is_connected(_refresh_hint) == false:
		InputSettings.bindings_changed.connect(_refresh_hint)

	if InputSettings.device_changed.is_connected(_on_device_changed) == false:
		InputSettings.device_changed.connect(_on_device_changed)

	_refresh_hint()

func _exit_tree() -> void:
	if Messages.input_hint_changed.is_connected(_on_input_hint_changed):
		Messages.input_hint_changed.disconnect(_on_input_hint_changed)

	if InputSettings.bindings_changed.is_connected(_refresh_hint):
		InputSettings.bindings_changed.disconnect(_refresh_hint)

	if InputSettings.device_changed.is_connected(_on_device_changed):
		InputSettings.device_changed.disconnect(_on_device_changed)

func _on_device_changed(_new_device: int) -> void:
	_refresh_hint()

func _on_input_hint_changed(prompt_name: String) -> void:
	current_prompt = prompt_name
	_refresh_hint()

func _refresh_hint() -> void:
	if icon_sprite == null:
		visible = false
		return

	if current_prompt.strip_edges() == "":
		visible = false
		return

	var action_name: StringName = _prompt_to_action(current_prompt)
	if action_name == &"":
		visible = false
		return

	var event: InputEvent = InputSettings.get_preferred_binding(action_name)
	if event == null:
		visible = false
		return

	var frame_index: int = _get_frame_for_event(event)
	if frame_index < 0:
		visible = false
		return

	icon_sprite.frame = frame_index
	visible = true

func _prompt_to_action(prompt_name: String) -> StringName:
	match prompt_name.to_lower():
		"interact":
			return &"action"
		"action":
			return &"action"
		"jump":
			return &"jump"
		"attack":
			return &"attack"
		"dash":
			return &"dash"
		"pause":
			return &"pause"
		"cast":
			return &"Cast"
		"up":
			return &"up"
		"down":
			return &"down"
		"left":
			return &"left"
		"right":
			return &"right"
		_:
			return &""

func _frame(col: int, row: int) -> int:
	return row * HFRAMES + col

func _get_frame_for_event(event: InputEvent) -> int:
	if event is InputEventMouseButton:
		return _get_mouse_frame((event as InputEventMouseButton).button_index)

	if event is InputEventJoypadButton:
		return _get_joy_button_frame((event as InputEventJoypadButton).button_index)

	if event is InputEventJoypadMotion:
		return _get_joy_motion_frame(event as InputEventJoypadMotion)

	if event is InputEventKey:
		return _get_key_frame((event as InputEventKey).physical_keycode)

	return -1

func _get_mouse_frame(button_index: MouseButton) -> int:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return _frame(18, 17)
		MOUSE_BUTTON_RIGHT:
			return _frame(19, 17)
		MOUSE_BUTTON_MIDDLE:
			return _frame(20, 17)
		MOUSE_BUTTON_WHEEL_UP:
			return _frame(21, 17)
		MOUSE_BUTTON_WHEEL_DOWN:
			return _frame(22, 17)
		MOUSE_BUTTON_XBUTTON1:
			return _frame(23, 17)
		MOUSE_BUTTON_XBUTTON2:
			return _frame(24, 17)
		_:
			return -1

func _get_joy_button_frame(button_index: int) -> int:
	match button_index:
		0:
			return _frame(0, 20)
		1:
			return _frame(1, 20)
		2:
			return _frame(2, 20)
		3:
			return _frame(3, 20)
		4:
			return _frame(8, 20)
		5:
			return _frame(9, 20)
		6:
			return _frame(8, 21)
		7:
			return _frame(9, 21)
		10:
			return _frame(13, 19)
		11:
			return _frame(14, 19)
		12:
			return _frame(15, 19)
		13:
			return _frame(16, 19)
		14:
			return _frame(17, 19)
		_:
			return -1

func _get_joy_motion_frame(event: InputEventJoypadMotion) -> int:
	match event.axis:
		0:
			if event.axis_value < 0.0:
				return _frame(3, 21)
			return _frame(4, 21)
		1:
			if event.axis_value < 0.0:
				return _frame(1, 21)
			return _frame(2, 21)
		2:
			return _frame(10, 20)
		3:
			return _frame(11, 20)
		_:
			return -1

func _get_key_frame(keycode: Key) -> int:
	match keycode:
		KEY_ESCAPE:
			return _frame(30, 0)

		KEY_1:
			return _frame(16, 1)
		KEY_2:
			return _frame(17, 1)
		KEY_3:
			return _frame(18, 1)
		KEY_4:
			return _frame(19, 1)
		KEY_5:
			return _frame(20, 1)
		KEY_6:
			return _frame(21, 1)
		KEY_7:
			return _frame(22, 1)
		KEY_8:
			return _frame(23, 1)
		KEY_9:
			return _frame(24, 1)
		KEY_0:
			return _frame(25, 1)

		KEY_Q:
			return _frame(17, 2)
		KEY_W:
			return _frame(18, 2)
		KEY_E:
			return _frame(19, 2)
		KEY_R:
			return _frame(20, 2)
		KEY_T:
			return _frame(21, 2)
		KEY_Y:
			return _frame(22, 2)
		KEY_U:
			return _frame(23, 2)
		KEY_I:
			return _frame(24, 2)
		KEY_O:
			return _frame(25, 2)
		KEY_P:
			return _frame(26, 2)

		KEY_A:
			return _frame(18, 3)
		KEY_S:
			return _frame(19, 3)
		KEY_D:
			return _frame(20, 3)
		KEY_F:
			return _frame(21, 3)
		KEY_G:
			return _frame(22, 3)
		KEY_H:
			return _frame(23, 3)
		KEY_J:
			return _frame(24, 3)
		KEY_K:
			return _frame(25, 3)
		KEY_L:
			return _frame(26, 3)

		KEY_Z:
			return _frame(19, 4)
		KEY_X:
			return _frame(20, 4)
		KEY_C:
			return _frame(21, 4)
		KEY_V:
			return _frame(22, 4)
		KEY_B:
			return _frame(23, 4)
		KEY_N:
			return _frame(24, 4)
		KEY_M:
			return _frame(25, 4)

		KEY_TAB:
			return _frame(14, 2)
		KEY_BACKSPACE:
			return _frame(31, 1)
		KEY_ENTER:
			return _frame(29, 3)

		KEY_SHIFT:
			return _frame(14, 4)
		KEY_CTRL:
			return _frame(14, 5)
		KEY_ALT:
			return _frame(16, 5)
		KEY_SPACE:
			return _frame(20, 5)

		KEY_UP:
			return _frame(31, 4)
		KEY_LEFT:
			return _frame(30, 5)
		KEY_DOWN:
			return _frame(31, 5)
		KEY_RIGHT:
			return _frame(32, 5)

		_:
			return -1
