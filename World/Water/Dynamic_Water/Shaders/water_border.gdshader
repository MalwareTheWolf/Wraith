shader_type canvas_item; 
// This shader is for 2D objects (Sprite2D, Polygon2D, etc.)

render_mode blend_mix; 
// Standard alpha blending (normal transparency behavior)

uniform vec4 _color : source_color; 
// The color that will be applied to the entire object.
// 'source_color' lets you edit it easily in the inspector.

uniform float wlevel_oscillation : hint_range(0.0, 8.0) = 3.0;
// Controls how strong the vertical wave movement is.
// Range is 0 to 8, default is 3.

void vertex() {
    // This runs for every vertex of the object.

    // Moves vertices up and down over time using a sine wave.
    // TIME is a built-in variable that increases constantly.
    // sin(TIME) creates smooth oscillation.
    VERTEX.y += sin(TIME) * wlevel_oscillation;
}

void fragment() {
    // This runs for every pixel.

    // Sets the final pixel color to the uniform color.
    COLOR = _color;
}