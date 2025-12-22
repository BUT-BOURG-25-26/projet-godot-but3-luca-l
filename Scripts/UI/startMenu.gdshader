shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 2.5;

void fragment() {
	vec4 color = vec4(0.0);
	float total = 0.0;
	int radius = 1.2;

	for (int x = -radius; x <= radius; x++) {
		for (int y = -radius; y <= radius; y++) {
			vec2 offset = vec2(float(x), float(y)) * blur_amount;
			color += texture(TEXTURE, UV + offset * TEXTURE_PIXEL_SIZE);
			total += 1.0;
		}
	}
	COLOR = color / total;
}