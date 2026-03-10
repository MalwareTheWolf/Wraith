shader_type canvas_item;
// 2D shader (used on Sprite2D, Polygon2D, etc.)

// Grab the rendered screen so we can create a reflection effect.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;

// Tint color applied to the water.
uniform vec4 color : source_color;

// Noise texture used to distort the reflection (creates ripple effect).
uniform sampler2D _noise : repeat_enable;

// Controls how fast the noise scrolls over time.
uniform float noise_speed : hint_range(0.0, 0.2) = 0.1;

// Controls the size of the noise pattern.
uniform float noise_scale : hint_range(0.0, 2.0) = 0.5;

// Controls how strongly the noise distorts the reflection.
uniform float noise_strength : hint_range(0.0, 5.0) = 1.0;

// Controls how tall the reflection stretch is.
uniform float scale_y : hint_range(1.0, 8.0) = 5.0;

// Vertical zoom of the distortion.
uniform float y_zoom : hint_range(0.8, 2.0) = 1.2;

// Moves the entire mesh up and down (water level motion).
uniform float wlevel_oscillation : hint_range(0.0, 8.0) = 3.0;

// Controls how smoothly the reflection fades into the normal screen.
uniform float fade : hint_range(0.0, 1.0) = 0.3;



void vertex() {
    // Moves the water surface up and down over time.
    // Creates a simple wave oscillation using sine.
    VERTEX.y += sin(TIME) * wlevel_oscillation;
}



void fragment() {

    // 1. Generate animated noise

    // Scale UVs and animate over time.
    vec2 uv_noise = UV * noise_scale + noise_speed * TIME;

    // Sample the noise texture (only red/green channels for 2D offset).
    vec2 noise = texture(_noise, uv_noise).rg;


    // 2. Calculate reflection UV

    // Adjust for differences between screen pixels and texture pixels.
    float uv_height = (SCREEN_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.y);

    // Create vertically flipped UV to simulate reflection.
    vec2 reflected_uv = vec2(
        SCREEN_UV.x,
        SCREEN_UV.y - (uv_height * UV.y * scale_y * y_zoom)
    );


    // 3. Sample screen for reflection

    // Sample reflected screen and distort it with animated noise.
    vec4 reflected = texture(
        screen_texture,
        reflected_uv + noise * y_zoom * (noise_strength / 100.0)
    );

    // Sample the normal screen (no reflection).
    vec4 screen = texture(screen_texture, SCREEN_UV);


    // 4. Apply water tint

    reflected = mix(reflected, color, 0.75);
    screen = mix(screen, color, 0.75);


    // 5. Fade reflection by depth

    // Smooth fade based on vertical UV position.
    float _smooth = smoothstep(0.0, fade, UV.y);

    // Blend reflection (top) into normal screen (bottom).
    COLOR = mix(reflected, screen, _smooth);
}