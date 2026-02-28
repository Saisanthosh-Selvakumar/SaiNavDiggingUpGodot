shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 1;
uniform float smoothness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // SCREEN_UV goes from (0,0) in bottom-left to (1,1) top-right
    vec2 uv = SCREEN_UV * 2.0 - 1.0; // center to (0,0)
    float dist = length(uv);
    float vignette = smoothstep(0.7 - smoothness, 0.7, dist);
    COLOR = mix(vec4(0.1), vignette_color, vignette * intensity);
}