@icon("uid://bvrool5ggsehu")
class_name DamageNumberSpawner extends Node2D

# Spawns floating damage numbers when a DamageableArea is hit.
# Uses Node2D containers so numbers exist in world space.

# --- TUNABLES ---

@export var label_settings: LabelSettings
# Visual style for damage numbers.

@export var critical_hit_color: Color = Color.RED
# Color used for critical hits.

@export var float_height: float = 40.0
# How far numbers float upward.

@export var duration: float = 0.6
# Duration of animation.

@export var target_path: NodePath
# Optional DamageableArea to auto-connect.

@export var spawn_offset: Vector2 = Vector2(0, -20)
# Offset applied to where damage numbers spawn (negative Y moves them upward).

# --- LIFECYCLE ---

func _ready() -> void:
	print("[DamageNumberSpawner] _ready called")

	var target: DamageableArea = null

	# Try target_path first
	if target_path != NodePath():
		target = get_node_or_null(target_path)
		if target and target is DamageableArea:
			print("[DamageNumberSpawner] Connected via target_path")

	# Fallback: parent
	if target == null and get_parent() is DamageableArea:
		target = get_parent()
		print("[DamageNumberSpawner] Connected to parent DamageableArea")

	# Connect signal
	if target:
		target.damage_taken.connect(_on_damage_taken)
	else:
		print("[DamageNumberSpawner] ERROR: No DamageableArea found!")

# --- SIGNAL HANDLERS ---

func _on_damage_taken(attack_area: AttackArea) -> void:
	if attack_area == null:
		return

	var damage := attack_area.damage

	# Spawn exactly at entity position + offset
	var parent_node := get_parent() as Node2D
	var spawn_pos: Vector2 = parent_node.global_position + spawn_offset

	spawn_label(damage, spawn_pos)

# --- SPAWNING ---

func spawn_label(number: float, world_pos: Vector2, critical_hit: bool = false) -> void:
	# Container node in world space
	var holder := Node2D.new()
	add_child(holder)
	holder.global_position = world_pos

	# Label inside holder
	var label := Label.new()
	holder.add_child(label)

	# Text formatting
	label.text = str(int(number)) if number == int(number) else str(number)

	# Apply style
	if label_settings:
		label.label_settings = label_settings.duplicate()

	# Critical hit color
	if critical_hit and label.label_settings:
		label.label_settings.font_color = critical_hit_color

	# Wait for size to center pivot
	await label.resized
	label.position = -label.size / 2

	# Small random variation
	holder.position += Vector2(
		randf_range(-5.0, 5.0),
		randf_range(-5.0, 5.0)
	)

	animate_label(holder)

# --- ANIMATION ---

func animate_label(holder: Node2D) -> void:
	var tween = create_tween()

	# Start smaller for pop effect
	holder.scale = Vector2(0.6, 0.6)

	# Move upward in world space
	tween.tween_property(holder, "position:y", holder.position.y - float_height, duration)

	# Fade out
	tween.parallel().tween_property(holder, "modulate:a", 0.0, duration)

	# Scale up slightly for pop
	tween.parallel().tween_property(holder, "scale", Vector2(1.2, 1.2), 0.2)

	# Free after animation
	tween.finished.connect(func():
		holder.queue_free()
	)
	
