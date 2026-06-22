shader_type canvas_item;
// 暗黑氛围光效 - 用于背景和面板
uniform vec4 glow_color : source_color = vec4(0.5, 0.2, 0.8, 0.3);
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.8;

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    
    // 暗角效果
    vec2 center = UV - vec2(0.5);
    float vignette = 1.0 - dot(center, center) * vignette_strength;
    vignette = clamp(vignette, 0.0, 1.0);
    
    // 脉冲光晕
    float pulse = sin(TIME * pulse_speed) * 0.3 + 0.7;
    vec4 glow = glow_color * glow_intensity * pulse;
    
    // 边缘发光
    float edge = smoothstep(0.4, 0.5, length(center));
    glow *= edge;
    
    COLOR = base * vignette + glow;
    COLOR.a = base.a;
}
