extends Control

@onready var root_box: VBoxContainer = get_node_or_null("VBoxContainer")
@onready var header_row: HBoxContainer = get_node_or_null("VBoxContainer/HeaderRow")
@onready var title_label: Label = get_node_or_null("VBoxContainer/HeaderRow/Title")
@onready var reset_button: Button = get_node_or_null("VBoxContainer/HeaderRow/ResetDefault")
@onready var scroll_container: ScrollContainer = get_node_or_null("VBoxContainer/ScrollContainer")
@onready var action_list: VBoxContainer = get_node_or_null("VBoxContainer/ScrollContainer/ActionList")
@onready var capture_label: Label = get_node_or_null("VBoxContainer/CaptureLabel")

var conflict_dialog: ConfirmationDialog

var waiting_for_input: bool = false
var pending_action: StringName = &""
var pending_index: int = -1
var pending_add_new: bool = false

var pending_conflict_event: InputEvent = null
var pending_conflicts: Array[Dictionary] = []

const HEADER_HEIGHT: float = 22.0
const RESET_BUTTON_W: float = 84.0

const UI_FONT_SIZE: int = 8
const TITLE_FONT_SIZE: int = 11
const ACTION_FONT_SIZE: int = 9
const GROUP_FONT_SIZE: int = 10

const BIND_BUTTON_W: float = 42.0
const BIND_BUTTON_H: float = 15.0
const SMALL_BUTTON_W: float = 15.0
const SMALL_BUTTON_H: float = 15.0
const ADD_BUTTON_W: float = 34.0

func _ready() -> void:
	if root_box == null or header_row == null or title_label == null or reset_button == null or scroll_container == null or action_list == null or capture_label == null:
		push_error("Controls page is missing one or more required nodes.")
		return

	root_box.add_theme_constant_override("separation", 3)

	header_row.custom_minimum_size = Vector2(0.0, HEADER_HEIGHT)
	header_row.add_theme_constant_override("separation", 4)

	title_label.text = "Controls"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_label.custom_minimum_size = Vector2(0.0, 18.0)
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)

	reset_button.text = "Reset Defaults"
	reset_button.tooltip_text = "Restore all controls to their default bindings."
	reset_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	reset_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reset_button.custom_minimum_size = Vector2(RESET_BUTTON_W, 18.0)
	reset_button.clip_text = true
	reset_button.add_theme_font_size_override("font_size", UI_FONT_SIZE)

	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_list.add_theme_constant_override("separation", 4)

	capture_label.visible = true
	capture_label.text = "Showing %s bindings." % InputSettings.get_current_device_label()
	capture_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	capture_label.add_theme_font_size_override("font_size", UI_FONT_SIZE)
	capture_label.custom_minimum_size = Vector2(0.0, 22.0)

	reset_button.pressed.connect(_on_reset_defaults_pressed)

	_setup_conflict_dialog()

	call_deferred("_refresh_layout")

func _setup_conflict_dialog() -> void:
	conflict_dialog = get_node_or_null("ConflictDialog")

	if conflict_dialog == null:
		conflict_dialog = ConfirmationDialog.new()
		conflict_dialog.name = "ConflictDialog"
		add_child(conflict_dialog)

	conflict_dialog.title = "Binding Conflict"
	conflict_dialog.dialog_text = ""
	conflict_dialog.exclusive = true
	conflict_dialog.process_mode = Node.PROCESS_MODE_ALWAYS

	if not conflict_dialog.confirmed.is_connected(_on_conflict_confirmed):
		conflict_dialog.confirmed.connect(_on_conflict_confirmed)

	if not conflict_dialog.canceled.is_connected(_on_conflict_canceled):
		conflict_dialog.canceled.connect(_on_conflict_canceled)

	var ok_button: Button = conflict_dialog.get_ok_button()
	if ok_button != null:
		ok_button.text = "Replace"

	var cancel_button: Button = conflict_dialog.get_cancel_button()
	if cancel_button != null:
		cancel_button.text = "Cancel"

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		call_deferred("_refresh_layout")

func _refresh_layout() -> void:
	if root_box == null or action_list == null:
		return
	rebuild_actions_ui()

func rebuild_actions_ui() -> void:
	for child in action_list.get_children():
		child.queue_free()

	var grouped: Dictionary = {}

	for action in InputSettings.get_visible_actions():
		var group_name: String = InputSettings.get_action_group(action)
		if not grouped.has(group_name):
			grouped[group_name] = []
		grouped[group_name].append(action)

	var group_order: Array[String] = ["Movement", "Combat", "Interaction", "Abilities", "Other"]

	for group_name in group_order:
		if not grouped.has(group_name):
			continue

		var header: Label = Label.new()
		header.text = group_name
		header.add_theme_font_size_override("font_size", GROUP_FONT_SIZE)
		action_list.add_child(header)

		for action in grouped[group_name]:
			action_list.add_child(_build_action_row(action))

func _build_action_row(action: StringName) -> Control:
	var available_width: float = maxf(180.0, root_box.size.x - 10.0)

	var outer: VBoxContainer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 2)

	var action_name: Label = Label.new()
	action_name.text = InputSettings.get_action_display_name(action)
	action_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_name.add_theme_font_size_override("font_size", ACTION_FONT_SIZE)
	outer.add_child(action_name)

	var flow: HFlowContainer = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.custom_minimum_size = Vector2(available_width, 0.0)
	flow.add_theme_constant_override("h_separation", 3)
	flow.add_theme_constant_override("v_separation", 3)
	outer.add_child(flow)

	var visible_events: Array[InputEvent] = InputSettings.get_bindings(action)
	var all_events: Array[InputEvent] = InputMap.action_get_events(action)

	for event in visible_events:
		var original_index: int = _find_original_event_index(all_events, event)

		var binding_button: Button = Button.new()
		binding_button.text = InputSettings.event_to_text(event)
		binding_button.clip_text = true
		binding_button.custom_minimum_size = Vector2(BIND_BUTTON_W, BIND_BUTTON_H)
		binding_button.focus_mode = Control.FOCUS_ALL
		binding_button.add_theme_font_size_override("font_size", UI_FONT_SIZE)
		binding_button.pressed.connect(_begin_rebind.bind(action, original_index, false))
		flow.add_child(binding_button)

		var remove_button: Button = Button.new()
		remove_button.text = "X"
		remove_button.custom_minimum_size = Vector2(SMALL_BUTTON_W, SMALL_BUTTON_H)
		remove_button.focus_mode = Control.FOCUS_ALL
		remove_button.tooltip_text = "Remove binding"
		remove_button.add_theme_font_size_override("font_size", UI_FONT_SIZE)
		remove_button.disabled = not InputSettings.can_remove_binding(action, original_index)
		if remove_button.disabled:
			remove_button.tooltip_text = "%s must keep at least one binding." % InputSettings.get_action_display_name(action)
		remove_button.pressed.connect(_remove_binding.bind(action, original_index))
		flow.add_child(remove_button)

	var add_button: Button = Button.new()
	add_button.text = "Add"
	add_button.custom_minimum_size = Vector2(ADD_BUTTON_W, SMALL_BUTTON_H)
	add_button.focus_mode = Control.FOCUS_ALL
	add_button.add_theme_font_size_override("font_size", UI_FONT_SIZE)
	add_button.pressed.connect(_begin_rebind.bind(action, -1, true))
	flow.add_child(add_button)

	var divider: HSeparator = HSeparator.new()
	outer.add_child(divider)

	return outer

func _find_original_event_index(all_events: Array[InputEvent], target_event: InputEvent) -> int:
	for i in range(all_events.size()):
		if InputSettings.events_equal(all_events[i], target_event):
			return i
	return -1

func _begin_rebind(action: StringName, index: int, add_new: bool) -> void:
	waiting_for_input = true
	pending_action = action
	pending_index = index
	pending_add_new = add_new
	pending_conflict_event = null
	pending_conflicts.clear()

	var device_label: String = InputSettings.get_current_device_label()

	if add_new:
		capture_label.text = "Press the new %s binding for %s. Esc or right click to cancel." % [
			device_label,
			InputSettings.get_action_display_name(action)
		]
	else:
		capture_label.text = "Press the replacement %s binding for %s. Esc or right click to cancel." % [
			device_label,
			InputSettings.get_action_display_name(action)
		]

func _input(event: InputEvent) -> void:
	if not waiting_for_input:
		return

	if conflict_dialog != null and conflict_dialog.visible:
		return

	if event is InputEventMouseMotion:
		return

	if event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) <= 0.5:
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
			_cancel_rebind("Rebind cancelled.")
			return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and key_event.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_cancel_rebind("Rebind cancelled.")
			return

	if not event.is_pressed():
		return

	get_viewport().set_input_as_handled()

	if not InputSettings.is_event_allowed(event):
		capture_label.text = "That input is not allowed. Choose another."
		return

	var event_copy: InputEvent = event.duplicate(true)
	var conflicts: Array[Dictionary] = InputSettings.find_conflicts(event_copy, pending_action, pending_index)

	if conflicts.size() > 0:
		_show_conflict_dialog(event_copy, conflicts)
		return

	_apply_pending_binding(event_copy)

func _show_conflict_dialog(event: InputEvent, conflicts: Array[Dictionary]) -> void:
	if conflict_dialog == null:
		capture_label.text = "That input is already used by another action."
		return

	var blocked_actions: Array[String] = []
	var swappable_actions: Array[String] = []

	for conflict in conflicts:
		var action: StringName = conflict["action"]
		var index: int = int(conflict["index"])

		if not InputSettings.can_remove_binding(action, index):
			blocked_actions.append(InputSettings.get_action_display_name(action))
		else:
			swappable_actions.append(InputSettings.get_action_display_name(action))

	if blocked_actions.size() > 0:
		capture_label.text = "That input is the last binding for %s and cannot be moved." % ", ".join(blocked_actions)
		return

	pending_conflict_event = event
	pending_conflicts = conflicts.duplicate(true)

	var target_name: String = InputSettings.get_action_display_name(pending_action)
	var input_name: String = InputSettings.event_to_text(event)
	var source_names: Array[String] = []

	for name in swappable_actions:
		if not source_names.has(name):
			source_names.append(name)

	conflict_dialog.dialog_text = "%s is already used by %s.\n\nMove it to %s instead?" % [
		input_name,
		", ".join(source_names),
		target_name
	]
	conflict_dialog.popup_centered(Vector2i(260, 120))

func _on_conflict_confirmed() -> void:
	if pending_conflict_event == null or pending_conflicts.is_empty():
		return

	for conflict in pending_conflicts:
		var action: StringName = conflict["action"]
		var index: int = int(conflict["index"])

		if not InputSettings.can_remove_binding(action, index):
			capture_label.text = "%s must keep at least one binding." % InputSettings.get_action_display_name(action)
			_clear_pending_conflict()
			return

	var grouped_conflicts: Dictionary = {}
	for conflict in pending_conflicts:
		var action: StringName = conflict["action"]
		if not grouped_conflicts.has(action):
			grouped_conflicts[action] = []
		grouped_conflicts[action].append(int(conflict["index"]))

	for action in grouped_conflicts.keys():
		var indexes: Array = grouped_conflicts[action]
		indexes.sort()
		indexes.reverse()

		for idx in indexes:
			var removed: bool = InputSettings.remove_binding(action, idx)
			if not removed:
				capture_label.text = "Could not reassign that binding."
				_clear_pending_conflict()
				rebuild_actions_ui()
				return

	_apply_pending_binding(pending_conflict_event)
	_clear_pending_conflict()

func _on_conflict_canceled() -> void:
	capture_label.text = "Choose another input or cancel rebinding."
	_clear_pending_conflict()

func _apply_pending_binding(event: InputEvent) -> void:
	var applied: bool = false

	if pending_add_new:
		applied = InputSettings.add_binding(pending_action, event.duplicate(true))
		if applied:
			capture_label.text = "Added %s to %s." % [
				InputSettings.event_to_text(event),
				InputSettings.get_action_display_name(pending_action)
			]
		else:
			capture_label.text = "That binding could not be added."
	else:
		applied = InputSettings.replace_binding(pending_action, pending_index, event.duplicate(true))
		if applied:
			capture_label.text = "Changed %s to %s." % [
				InputSettings.get_action_display_name(pending_action),
				InputSettings.event_to_text(event)
			]
		else:
			capture_label.text = "That replacement is not allowed."

	if not applied:
		return

	_finish_rebind()
	rebuild_actions_ui()

func _remove_binding(action: StringName, index: int) -> void:
	if not InputSettings.can_remove_binding(action, index):
		capture_label.text = "%s must keep at least one binding." % InputSettings.get_action_display_name(action)
		return

	var removed: bool = InputSettings.remove_binding(action, index)
	if removed:
		capture_label.text = "Removed a binding from %s." % InputSettings.get_action_display_name(action)
	else:
		capture_label.text = "That binding could not be removed."

	rebuild_actions_ui()

func _on_reset_defaults_pressed() -> void:
	InputSettings.reset_to_defaults(true)
	_finish_rebind()
	_clear_pending_conflict()
	capture_label.text = "Controls reset to defaults."
	rebuild_actions_ui()

func _cancel_rebind(message: String = "Rebind cancelled.") -> void:
	_finish_rebind()
	_clear_pending_conflict()
	capture_label.text = message

func _finish_rebind() -> void:
	waiting_for_input = false
	pending_action = &""
	pending_index = -1
	pending_add_new = false

func _clear_pending_conflict() -> void:
	pending_conflict_event = null
	pending_conflicts.clear()
