# lightning_effect.gd
extends Node2D

@export var base_damage: float = 20
var modifiers: Array = []

func setup(mods: Array):
	modifiers = mods

func cast(origin: Vector2, direction: Vector2):
	position = origin
	rotation = direction.angle()
	
	# Apply all modifiers
	for mod in modifiers:
		if mod is ChainLightningModifier:
			apply_chain_lightning(mod)
		elif mod is SkyLightningModifier:
			apply_sky_lightning(mod)
	
	# Simple visual for demo
	if $Line2D:
		$Line2D.global_position = origin
		$Line2D.points = [Vector2.ZERO, direction * 300]

func apply_chain_lightning(mod: ChainLightningModifier):
	var enemies = get_nearby_enemies(position, mod.jump_range, mod.max_jumps)
	for e in enemies:
		if e.has_method("take_damage"):
			e.take_damage(base_damage)

func apply_sky_lightning(mod: SkyLightningModifier):
	position.y -= mod.strike_height
	base_damage *= mod.damage_multiplier

# Helper function (replace with your game’s enemy detection)
func get_nearby_enemies(pos: Vector2, radius: float, max_targets: int):
	var enemies: Array = []
	# Placeholder: Replace with real logic
	for node in get_tree().get_nodes_in_group("Enemies"):
		if node.global_position.distance_to(pos) <= radius:
			enemies.append(node)
			if enemies.size() >= max_targets:
				break
	return enemies
