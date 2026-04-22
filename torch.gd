extends Node2D

@export var start_lit: bool = false
@export var debug_allow_test_toggle: bool = true
@export var debug_toggle_key: Key = KEY_T

@onready var unlit_sprite: Sprite2D = $Sprite2D
@onready var lit_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light: PointLight2D = $PointLight2D
@onready var hitbox: Area2D = $Area2D

var lit: bool = false

func _ready() -> void:
	set_lit(start_lit)

	if hitbox != null:
		if not hitbox.area_entered.is_connected(_on_area_entered):
			hitbox.area_entered.connect(_on_area_entered)
		if not hitbox.body_entered.is_connected(_on_body_entered):
			hitbox.body_entered.connect(_on_body_entered)

func _input(event: InputEvent) -> void:
	if not debug_allow_test_toggle:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.physical_keycode == debug_toggle_key:
			toggle_lit()

func set_lit(value: bool) -> void:
	lit = value

	if unlit_sprite != null:
		unlit_sprite.visible = not lit

	if lit_sprite != null:
		lit_sprite.visible = lit
		if lit:
			if lit_sprite.sprite_frames != null and lit_sprite.sprite_frames.get_animation_names().has("default"):
				lit_sprite.play("default")
			else:
				lit_sprite.play()
		else:
			lit_sprite.stop()

	if light != null:
		light.enabled = lit

func ignite() -> void:
	if lit:
		return
	set_lit(true)

func extinguish() -> void:
	if not lit:
		return
	set_lit(false)

func toggle_lit() -> void:
	set_lit(not lit)

func _on_area_entered(area: Area2D) -> void:
	if lit:
		return

	if area.is_in_group("fire_spell"):
		ignite()

func _on_body_entered(body: Node) -> void:
	if lit:
		return

	if body.is_in_group("fire_spell"):
		ignite()
