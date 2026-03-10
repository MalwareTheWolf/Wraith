@tool
extends Node2D
# Lets the water update visually while editing the scene.


# ---------------- PHYSICS ----------------
@export_category("Physics")
@export var k: float = 0.015
@export var d: float = 0.03
@export var spread: float = 0.5


# ---------------- VISUALS ----------------
@export_category("Visuals")
@export var width: int = 300
@export var spring_number: int = 7
@export var _depth: int = 5


# NODE REFERENCES
@onready var water_spring: PackedScene = preload("res://World/Water/Dynamic_Water/Scenes/water_spring.tscn")
@onready var water_polygon: Polygon2D = null
@onready var water_border: SmoothPath = null


# ---------------- VARIABLES ----------------
var springs: Array[WaterSpring] = []
var passes: int = 8
var target_height: float = 0
var bottom: float = 0
var effective_spread: float
var _script_ready: bool = false


# ---------------- LIFECYCLE ----------------
func _ready() -> void:
	# Assign node references safely
	water_polygon = $Water_Polygon
	water_border = $Water_Border

	target_height = 0
	bottom = target_height + _depth

	initialize_springs()

	if Engine.is_editor_hint():
		update_visuals()

	_script_ready = true


func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		calculate_springs()
		update_visuals()


# ---------------- SPRING INITIALIZATION ----------------
func initialize_springs() -> void:
	clear_springs()

	var springs_gap = float(width) / max(1, (spring_number - 1))

	for i in range(spring_number):
		var x_position = springs_gap * i

		var w: WaterSpring = water_spring.instantiate()
		add_child(w)
		springs.append(w)

		w.initialize(x_position, i)
		w.splash.connect(splash)


func clear_springs() -> void:
	for spring in springs:
		if spring:
			spring.queue_free()
	springs.clear()


# ---------------- PHYSICS UPDATE ----------------
func calculate_springs() -> void:
	effective_spread = spread / 1000.0

	for spring in springs:
		spring.water_update(k, d)

	for i in range(springs.size()):
		var left_neighbor = i - 1
		if left_neighbor >= 0:
			var left_delta = effective_spread * (springs[i].height - springs[left_neighbor].height)
			springs[i].velocity -= left_delta
			springs[left_neighbor].velocity += left_delta

		var right_neighbor = i + 1
		if right_neighbor < springs.size():
			var right_delta = effective_spread * (springs[i].height - springs[right_neighbor].height)
			springs[i].velocity -= right_delta
			springs[right_neighbor].velocity += right_delta


# ---------------- EDITOR UPDATES ----------------
func update_editor() -> void:
	if not _script_ready:
		return

	bottom = target_height + _depth
	initialize_springs()
	update_visuals()


# ---------------- VISUAL GENERATION ----------------
func update_visuals() -> void:
	new_border()
	draw_water_body()


func new_border() -> void:
	if water_border.curve:
		water_border.curve.clear_points()

	var curve = Curve2D.new()
	for spring in springs:
		curve.add_point(spring.position)

	water_border.curve = curve
	water_border.smooth()
	water_border.queue_redraw()


func draw_water_body() -> void:
	var water_polygon_points = []
	var curve = water_border.curve

	if curve:
		water_polygon_points = Array(curve.get_baked_points()).duplicate()

	if water_polygon_points.size() > 0:
		var last_point = water_polygon_points[water_polygon_points.size() - 1]
		var first_point = water_polygon_points[0]

		water_polygon_points.append(Vector2(last_point.x, bottom))
		water_polygon_points.append(Vector2(first_point.x, bottom))

	water_polygon.polygon = PackedVector2Array(water_polygon_points)


# ---------------- INTERACTION ----------------
func splash(index: int, speed: float) -> void:
	if index >= 0 and index < springs.size():
		springs[index].velocity += speed
