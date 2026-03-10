@tool
class_name SmoothPath
extends Path2D
# Custom Path2D that can automatically smooth its Curve2D
# by adjusting control handles based on neighboring points.


#            EXPORTS

@export var spline_length = 8
# Controls how long the bezier handles are when smoothing.
# Larger value = softer, wider curves.
# Smaller value = tighter curves.

@export_tool_button("Smooth Curve", "Play")
var sm = smooth
# Adds a button in the editor to smooth the curve.

@export_tool_button("Straghten Curve", "Play")
var st = straighten
# Adds a button in the editor to remove all curve handles (make straight lines).


# Reference to a Line2D used for visual debugging/drawing.
@onready var line: Line2D = $Line2D



#          CURVE CONTROL

func straighten() -> void:
	# Removes all bezier handles from every point.
	# This converts the curve into straight segments.
	for i in range(curve.get_point_count()):
		curve.set_point_in(i, Vector2.ZERO)
		curve.set_point_out(i, Vector2.ZERO)



# Smooths the curve by generating bezier handles
# based on neighboring point directions.
func smooth() -> void:

	var point_count = curve.get_point_count()

	# Skip first and last point to avoid out-of-range issues
	for i in range(1, point_count - 1):

		var spline = _get_spline(i)

		# Set symmetric bezier handles
		curve.set_point_in(i, -spline)
		curve.set_point_out(i, spline)



#       SPLINE CALCULATION

# Calculates a bezier handle direction for point i
# based on its neighboring points.
func _get_spline(i: int) -> Vector2:

	var last_point = _get_point(i - 1)
	var next_point = _get_point(i + 1)

	# Create direction vector between neighbors
	# and scale it by spline_length
	return last_point.direction_to(next_point) * spline_length



# Safely retrieves a point position,
# wrapping around the curve if needed.
func _get_point(i: int) -> Vector2:

	var point_count = curve.get_point_count()

	# Ensures index loops within valid range
	i = wrapi(i, 0, point_count)

	return curve.get_point_position(i)



#            DRAWING

# Draws the smoothed curve using baked points.
# Baked points are the interpolated final curve positions.
func _draw() -> void:

	var points = curve.get_baked_points()

	if points.size() > 0:
		line.points = points
