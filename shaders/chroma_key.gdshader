shader_type canvas_item;

// 色度键(Chroma Key)着色器 - 去除纯绿色背景
uniform vec3 key_color : source_color = vec3(0.0, 1.0, 0.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.45;
uniform float smoothing : hint_range(0.0, 0.5) = 0.12;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float dist = distance(tex_color.rgb, key_color);
	float alpha = smoothstep(threshold - smoothing, threshold + smoothing, dist);
	COLOR = vec4(tex_color.rgb, tex_color.a * alpha);
}
