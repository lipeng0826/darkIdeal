shader_type canvas_item;
// 装备品质发光着色器
uniform vec4 rarity_color : source_color = vec4(1.0, 0.6, 0.0, 1.0);
uniform float glow_strength : hint_range(0.0, 3.0) = 1.0;
uniform float animation_speed : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    
    // 品质光环
    float pulse = sin(TIME * animation_speed) * 0.4 + 0.6;
    float border = smoothstep(0.0, 0.1, UV.x) * smoothstep(0.0, 0.1, UV.y)
                 * smoothstep(0.0, 0.1, 1.0 - UV.x) * smoothstep(0.0, 0.1, 1.0 - UV.y);
    float glow_mask = 1.0 - border;
    
    vec4 glow = rarity_color * glow_strength * pulse * glow_mask;
    
    COLOR = base + glow;
    COLOR.a = base.a;
}
