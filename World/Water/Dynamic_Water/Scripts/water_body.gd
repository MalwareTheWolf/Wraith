@tool
extends Node2D
# Allows this script to run inside the editor.
# This lets the water update visually while editing the scene.


#            PHYSICS

@export_category("Physics")

## Spring stiffness (Hooke's Law constant).
## Higher value = snaps back faster.
@export var k: float = 0.015

## Damping factor.
## Reduces oscillation over time.
## Higher value = water settles faster.
@export var d: float = 0.03

## Spread factor.
## Controls how much movement transfers to neighboring springs.
@export var spread: float = 0.5



#            VISUALS

@export_category("Visuals")

## Total horizontal width of the water system.
@export var width: int = 300:
	set(value):
		width = value
		update_editor()

## Number of springs across the surface.
## More springs = smoother water but more processing.
@export var spring_number: int = 7:
	set(value):
		spring_number = value
		update_editor()

## Depth of the water body.
## Determines how far down the polygon extends.
@export var _depth: int = 5:
	set(value):
		_depth = value
		update_editor()



#        NODE REFERENCES

# Spring scene that gets instanced across the surface.
@onready var water_spring = preload("res://Water Stuff/addons/Dynamic_Water/Scenes/water_spring.tscn")

# Polygon used to draw the filled water body.
@onready var water_polygon: Polygon2D = %Water_Polygon

# Path used to generate the smooth water surface.
@onready var water_border: SmoothPath = %Water_Border



#          VARIABLES

# Array holding all active springs.
var springs: Array[WaterSpring] = []

# Number of neighbor spread passes (unused currently but common in wave sims).
var passes: int = 8

# Target equilibrium height of the springs.
var target_height: float = 0

# Bottom Y position of the water.
var bottom: float = 0

# Adjusted spread value used in simulation.
var effective_spread: float

# Used to prevent editor updates before ready.
var _script_ready: bool



#           LIFECYCLE

func _ready() -> void:
	target_height = 0
	bottom = target_height + _depth

	initialize_springs()

	# Only update visuals immediately in editor mode
	if Engine.is_editor_hint():
		update_visuals()

	_script_ready = true


func _physics_process(_delta: float) -> void:
	# Only simulate during gameplay
	if not Engine.is_editor_hint():
		calculate_springs()
		update_visuals()



#      SPRING INITIALIZATION

func initialize_springs() -> void:
	clear_springs()

	# Distance between each spring along width
	var springs_gap = float(width) / max(1, (spring_number - 1))

	for i in range(spring_number):
		var x_position = springs_gap * i

		var w: WaterSpring = water_spring.instantiate()
		add_child(w)
		springs.append(w)

		# Initialize spring position and index
		w.initialize(x_position, i)

		# Connect splash signal
		w.splash.connect(splash)


func clear_springs() -> void:
	# Removes all existing springs
	for spring in springs:
		if spring:
			spring.queue_free()

	springs.clear()



#        PHYSICS UPDATE

func calculate_springs() -> void:

	# Reduce spread to a small usable simulation value
	effective_spread = spread / 1000.0

	# Update individual spring physics
	for spring in springs:
		spring.water_update(k, d)

	# Transfer wave energy between neighbors
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



#        EDITOR UPDATES

func update_editor() -> void:
	if !_script_ready:
		return

	bottom = target_height + _depth
	initialize_springs()
	update_visuals()



#        VISUAL GENERATION

func update_visuals() -> void:
	new_border()
	draw_water_body()


func new_border() -> void:
	# Rebuild the smooth water surface path

	if water_border.curve:
		water_border.curve.clear_points()

	var curve = Curve2D.new()

	for spring in springs:
		curve.add_point(spring.position)

	water_border.curve = curve
	water_border.smooth()
	water_border.queue_redraw()


func draw_water_body() -> void:
	# Build the filled polygon from the smoothed surface

	var water_polygon_points = []
	var curve = water_border.curve

	if curve:
		water_polygon_points = Array(curve.get_baked_points()).duplicate()

	if water_polygon_points.size() > 0:

		var last_point = water_polygon_points[water_polygon_points.size() - 1]
		var first_point = water_polygon_points[0]

		# Extend polygon downward to form closed water body
		water_polygon_points.append(Vector2(last_point.x, bottom))
		water_polygon_points.append(Vector2(first_point.x, bottom))

	water_polygon.polygon = PackedVector2Array(water_polygon_points)



#          INTERACTION

func splash(index: int, speed: float) -> void:
	# Adds velocity to a specific spring to create a splash

	if index >= 0 and index < springs.size():
		springs[index].velocity += speed
