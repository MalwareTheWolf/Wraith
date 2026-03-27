class_name Spell extends Resource

@export var name: String
@export var description: String
@export var mana_cost: float = 10.0
@export var cooldown: float = 1.0
@export var cast_type: String = "aimed" # aimed, instant, channel
@export var effect_scene: PackedScene # scene that handles visuals & behavior
@export var modifiers: Array[Resource] = [] # optional modifiers
