shader_type canvas_item;
// 粒子特效着色器 - 用于战斗特效
uniform vec4 particle_color : source_color = vec4(1.0, 0.3, 0.1, 1.0);
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float glow : hint_range(0.0, 3.0) = 1.5;

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    
    // 噪声溶解
    float noise = fract(sin(dot(UV, vec2(12.9898, 78.233))) * 43758.5453);
    float alpha = step(dissolve, noise);
    
    // 边缘发光
    float edge = smoothstep(dissolve - 0.1, dissolve, noise) - alpha;
    vec4 edge_glow = particle_color * glow * edge;
    
    COLOR = (base + edge_glow) * particle_color;
    COLOR.a = base.a * alpha + edge * 0.5;
}
