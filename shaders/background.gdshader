shader_type canvas_item;
render_mode unshaded;

const vec2 PIXEL_RESOLUTION = vec2(240.0, 135.0);
const float SPIN_ROTATION_SPEED = 0.25;
const float MOVE_SPEED = 2.5;
const bool IS_ROTATING = true;
const vec2 OFFSET = vec2(0.0, 0.0);
const float CONTRAST = 2.0;
const float LIGHTING = 1.0;
const float SPIN_AMOUNT = 0.1;
const vec4 COLOR_1 = vec4(0.09375, 0.078125, 0.14453125, 1.0);
const vec4 COLOR_2 = vec4(0.40625, 0.21875, 0.421875, 1.0);
const vec4 COLOR_3 = vec4(0.9609375, 0.45703125, 0.4765625, 1.0);
const float SPIN_EASE = 1.0;


vec4 effect(vec2 resolution, vec2 screen_coords) {
	vec2 pixel_coords = floor(screen_coords * resolution) + 0.5;
	vec2 uv = (pixel_coords - resolution * 0.5) / length(resolution) - OFFSET;
	float uv_len = length(uv);
	float speed = SPIN_ROTATION_SPEED * SPIN_EASE * 0.2;

	if (IS_ROTATING) {
		speed = TIME * speed;
	}

	speed += 300.0;

	float angle = atan(uv.y, uv.x) + speed - SPIN_EASE * 20.0 * (SPIN_AMOUNT * uv_len + (1.0 - SPIN_AMOUNT));

	uv = uv_len * vec2(cos(angle), sin(angle));
	uv *= 30.0;
	speed = TIME * MOVE_SPEED;

	vec2 uv2 = vec2(uv.x + uv.y);

	for (int i = 0; i < 5; i++) {
		uv2 += sin(max(uv.x, uv.y)) + uv;
		uv += 0.5 * vec2(cos(5.0 + 0.35 * uv2.y + speed * 0.15), sin(uv2.x - 0.1 * speed));
		uv -= cos(uv.x + uv.y) - sin(uv.x * 0.7 - uv.y);
	}

	float contrast_mod = 0.25 * CONTRAST + 0.5 * SPIN_AMOUNT + 1.2;
	float paint_res = clamp(length(uv) * 0.035 * contrast_mod, 0.0, 2.0);
	float c1p = max(0.0, 1.0 - contrast_mod * abs(1.0 - paint_res));
	float c2p = max(0.0, 1.0 - contrast_mod * abs(paint_res));
	float c3p = 1.0 - min(1.0, c1p + c2p);
	float light = (LIGHTING - 0.2) * max(c1p * 5.0 - 4.0, 0.0) + LIGHTING * max(c2p * 5.0 - 4.0, 0.0);
	vec4 result = (0.3 / CONTRAST) * COLOR_1 + (1.0 - 0.3 / CONTRAST) * (COLOR_1 * c1p + COLOR_2 * c2p + vec4(c3p * COLOR_3.rgb, c3p * COLOR_1.a));

	result.rgb += vec3(light);

	return result;
}


void fragment() {
	COLOR = effect(PIXEL_RESOLUTION, UV) * COLOR;
}
