extends Node

const SETTINGS_PATH := "user://input_settings.cfg"

enum InputDevice {
	KEYBOARD_MOUSE,
	CONTROLLER
}

var current_device: InputDevice = InputDevice.KEYBOARD_MOUSE
var default_bindings: Dictionary = {}

const BASE_ACTIONS: Array[StringName] = [
	&"left",
	&"right",
	&"up",
	&"down",
	&"jump",
	&"attack",
	&"action",
	&"pause"
]

# Edit these action names to match your Input Map exactly.
const ABILITY_ACTIONS: Dictionary = {
	"dash": &"dash",
	"lightning": &"lightning",
	"Chain_lightning": &"chain_lightning",
	"dark_blast": &"dark_blast",
	"heavy_attack": &"heavy_attack",
	"power_up": &"power_up",
	"ground_slam": &"ground_slam",
	"morph": &"morph",
	"spell2": &"spell2",
	"spell3": &"spell3",
	"spell4": &"spell4",
	"spell5": &"spell5",
	"spell6": &"spell6",
	"spell7": &"spell7",
	"spell8": &"spell8"
}

func _ready() -> void:
	cache_defaults()
	load_bindings()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		current_device = InputDevice.CONTROLLER
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		current_device = InputDevice.CONTROLLER
	elif event is InputEventKey or event is InputEventMouseButton:
		current_device = InputDevice.KEYBOARD_MOUSE

func cache_defaults() -> void:
	default_bindings.clear()

	for action in _get_all_known_actions():
		if InputMap.has_action(action):
			default_bindings[action] = _duplicate_events(InputMap.action_get_events(action))

func _get_all_known_actions() -> Array[StringName]:
	var actions: Array[StringName] = []

	for action in BASE_ACTIONS:
		if not actions.has(action):
			actions.append(action)

	for value in ABILITY_ACTIONS.values():
		var action: StringName = value
		if not actions.has(action):
			actions.append(action)

	return actions

func get_visible_actions() -> Array[StringName]:
	var actions: Array[StringName] = []

	for action in BASE_ACTIONS:
		if InputMap.has_action(action):
			actions.append(action)

	var player := get_tree().get_first_node_in_group("Player")
	if player == null:
		return actions

	for ability_name in ABILITY_ACTIONS.keys():
		if not bool(player.get(ability_name)):
			continue

		var action_name: StringName = ABILITY_ACTIONS[ability_name]
		if InputMap.has_action(action_name) and not actions.has(action_name):
			actions.append(action_name)

	return actions

func get_action_group(action: StringName) -> String:
	match String(action):
		"left", "right", "up", "down", "jump", "dash", "morph":
			return "Movement"
		"attack", "heavy_attack", "lightning", "chain_lightning", "dark_blast", "power_up", "ground_slam":
			return "Combat"
		"action", "pause":
			return "Interaction"
		"spell2", "spell3", "spell4", "spell5", "spell6", "spell7", "spell8":
			return "Abilities"
		_:
			return "Other"

func get_current_device_label() -> String:
	return "Keyboard / Mouse" if current_device == InputDevice.KEYBOARD_MOUSE else "Controller"

func save_bindings() -> void:
	var config := ConfigFile.new()

	for action in _get_all_known_actions():
		if not InputMap.has_action(action):
			continue

		var events: Array[InputEvent] = InputMap.action_get_events(action)
		var serialized: Array = []

		for event in events:
			var data: Dictionary = serialize_event(event)
			if not data.is_empty():
				serialized.append(data)

		config.set_value("input", String(action), serialized)

	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("Failed to save input settings. Error code: %s" % err)

func load_bindings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)

	if err != OK:
		reset_to_defaults(false)
		return

	for action in _get_all_known_actions():
		if not InputMap.has_action(action):
			continue

		InputMap.action_erase_events(action)

		var saved_events: Array = config.get_value("input", String(action), [])
		for item in saved_events:
			var event: InputEvent = deserialize_event(item)
			if event != null:
				InputMap.action_add_event(action, event)

func reset_to_defaults(save: bool = true) -> void:
	for action in _get_all_known_actions():
		if not InputMap.has_action(action):
			continue

		InputMap.action_erase_events(action)

		var defaults: Array = default_bindings.get(action, [])
		for event in defaults:
			InputMap.action_add_event(action, event)

	if save:
		save_bindings()

func add_binding(action: StringName, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	if not is_event_allowed(event):
		return
	if action_has_exact_event(action, event):
		return

	InputMap.action_add_event(action, event)
	save_bindings()

func replace_binding(action: StringName, index: int, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	if not is_event_allowed(event):
		return

	var events: Array[InputEvent] = InputMap.action_get_events(action)
	if index < 0 or index >= events.size():
		return

	var old_event: InputEvent = events[index]
	InputMap.action_erase_event(action, old_event)

	if not action_has_exact_event(action, event):
		InputMap.action_add_event(action, event)

	save_bindings()

func remove_binding(action: StringName, index: int) -> void:
	if not InputMap.has_action(action):
		return

	var events: Array[InputEvent] = InputMap.action_get_events(action)
	if index < 0 or index >= events.size():
		return

	InputMap.action_erase_event(action, events[index])
	save_bindings()

func get_bindings(action: StringName) -> Array[InputEvent]:
	if not InputMap.has_action(action):
		return []

	var all_events: Array[InputEvent] = InputMap.action_get_events(action)
	var filtered: Array[InputEvent] = []

	for event in all_events:
		if current_device == InputDevice.KEYBOARD_MOUSE:
			if event is InputEventKey or event is InputEventMouseButton:
				filtered.append(event)
		else:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				filtered.append(event)

	return filtered

func get_action_display_name(action: StringName) -> String:
	match String(action):
		"left": return "Move Left"
		"right": return "Move Right"
		"up": return "Move Up"
		"down": return "Move Down"
		"jump": return "Jump"
		"attack": return "Attack"
		"dash": return "Dash"
		"action": return "Interact"
		"pause": return "Pause"
		"lightning": return "Lightning"
		"chain_lightning": return "Chain Lightning"
		"dark_blast": return "Dark Blast"
		"heavy_attack": return "Heavy Attack"
		"power_up": return "Power Up"
		"ground_slam": return "Ground Slam"
		"morph": return "Morph"
		"spell2": return "Spell 2"
		"spell3": return "Spell 3"
		"spell4": return "Spell 4"
		"spell5": return "Spell 5"
		"spell6": return "Spell 6"
		"spell7": return "Spell 7"
		"spell8": return "Spell 8"
		_: return String(action).capitalize()

func find_conflicts(event: InputEvent, ignored_action: StringName = &"", ignored_index: int = -1) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for action in _get_all_known_actions():
		if not InputMap.has_action(action):
			continue

		var events: Array[InputEvent] = InputMap.action_get_events(action)
		for i in range(events.size()):
			if action == ignored_action and i == ignored_index:
				continue

			if events_equal(events[i], event):
				results.append({
					"action": action,
					"index": i
				})

	return results

func is_event_allowed(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var code: Key = key_event.physical_keycode

		if code == KEY_ESCAPE or code == KEY_QUOTELEFT:
			return false

		if code >= KEY_F1 and code <= KEY_F12:
			return false

		return true

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.button_index in [
			MOUSE_BUTTON_LEFT,
			MOUSE_BUTTON_RIGHT,
			MOUSE_BUTTON_MIDDLE,
			MOUSE_BUTTON_WHEEL_UP,
			MOUSE_BUTTON_WHEEL_DOWN,
			MOUSE_BUTTON_XBUTTON1,
			MOUSE_BUTTON_XBUTTON2
		]

	if event is InputEventJoypadButton:
		return true

	if event is InputEventJoypadMotion:
		return absf((event as InputEventJoypadMotion).axis_value) > 0.5

	return false

func event_to_text(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return OS.get_keycode_string(key_event.physical_keycode)

	if event is InputEventMouseButton:
		var button: MouseButton = (event as InputEventMouseButton).button_index
		match button:
			MOUSE_BUTTON_LEFT: return "Mouse Left"
			MOUSE_BUTTON_RIGHT: return "Mouse Right"
			MOUSE_BUTTON_MIDDLE: return "Mouse Middle"
			MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
			MOUSE_BUTTON_XBUTTON1: return "Mouse Button 4"
			MOUSE_BUTTON_XBUTTON2: return "Mouse Button 5"
			_: return "Mouse Button %d" % button

	if event is InputEventJoypadButton:
		var joy := event as InputEventJoypadButton
		return "Pad Button %d" % joy.button_index

	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		var sign_text := "+" if motion.axis_value > 0.0 else "-"
		return "Pad Axis %d %s" % [motion.axis, sign_text]

	return "Unknown"

func serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var e := event as InputEventKey
		return {
			"type": "key",
			"physical_keycode": e.physical_keycode
		}

	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		return {
			"type": "mouse_button",
			"button_index": e.button_index
		}

	if event is InputEventJoypadButton:
		var e := event as InputEventJoypadButton
		return {
			"type": "joypad_button",
			"button_index": e.button_index
		}

	if event is InputEventJoypadMotion:
		var e := event as InputEventJoypadMotion
		return {
			"type": "joypad_motion",
			"axis": e.axis,
			"axis_value": 1.0 if e.axis_value >= 0.0 else -1.0
		}

	return {}

func deserialize_event(data: Dictionary) -> InputEvent:
	match data.get("type", ""):
		"key":
			var e := InputEventKey.new()
			e.physical_keycode = int(data.get("physical_keycode", 0))
			return e

		"mouse_button":
			var e := InputEventMouseButton.new()
			e.button_index = int(data.get("button_index", 0))
			e.pressed = true
			return e

		"joypad_button":
			var e := InputEventJoypadButton.new()
			e.button_index = int(data.get("button_index", 0))
			e.pressed = true
			return e

		"joypad_motion":
			var e := InputEventJoypadMotion.new()
			e.axis = int(data.get("axis", 0))
			e.axis_value = float(data.get("axis_value", 1.0))
			return e

	return null

func action_has_exact_event(action: StringName, new_event: InputEvent) -> bool:
	for event in InputMap.action_get_events(action):
		if events_equal(event, new_event):
			return true
	return false

func events_equal(a: InputEvent, b: InputEvent) -> bool:
	if a == null or b == null:
		return false

	if a.get_class() != b.get_class():
		return false

	if a is InputEventKey and b is InputEventKey:
		return (a as InputEventKey).physical_keycode == (b as InputEventKey).physical_keycode

	if a is InputEventMouseButton and b is InputEventMouseButton:
		return (a as InputEventMouseButton).button_index == (b as InputEventMouseButton).button_index

	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return (a as InputEventJoypadButton).button_index == (b as InputEventJoypadButton).button_index

	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return (
			(a as InputEventJoypadMotion).axis == (b as InputEventJoypadMotion).axis
			and signf((a as InputEventJoypadMotion).axis_value) == signf((b as InputEventJoypadMotion).axis_value)
		)

	return false

func _duplicate_events(events: Array) -> Array:
	var out: Array = []
	for event in events:
		out.append(event.duplicate(true))
	return out
