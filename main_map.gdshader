shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(0.2, 0.6, 1.0, 1.0); // Default blue
uniform float progress : hint_range(0, 1) = 0.5; // Current fill amount
uniform bool rainbow_mode = false; // Toggle rainbow effect
uniform float rainbow_speed = 0.5; // Rainbow animation speed
uniform float rainbow_saturation = 0.8; // Color intensity

void fragment() {
    // Only show pixels that should be filled based on progress
    if (UV.x > progress) {
        discard;
    }
    
    if (rainbow_mode) {
        // Animated rainbow effect
        float hue = fract(TIME * rainbow_speed + UV.x * 0.3);
        vec3 rgb = mix(
            vec3(1.0),
            clamp(
                abs(fract(hue + vec3(1.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0) - 1.0,
                0.0,
                1.0
            ),
            rainbow_saturation
        );
        COLOR = vec4(rgb, 1.0);
    } else {
        // Normal fill color
        COLOR = fill_color;
    }
}