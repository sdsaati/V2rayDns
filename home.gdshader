shader_type canvas_item;

// Speed of time effect
uniform float speed : hint_range(0.0, 10.0) = 1.5;

// Intensity of UV distortion
uniform float distortion_amount : hint_range(0.0, 0.5) = 0.08;

// Strength of RGB split
uniform float rgb_shift_strength : hint_range(0.0, 0.05) = 0.02;

// Scanline intensity/contrast
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.6;

void fragment() {
    // Base UV
    vec2 uv = UV;

    // Time warp value
    float t = TIME * speed;

    // Animated distortion (UV flicker + time)
    float distort_x = sin((uv.y + t) * 30.0) * distortion_amount;
    float distort_y = cos((uv.x - t) * 30.0) * distortion_amount;

    vec2 uv_distorted = uv + vec2(distort_x, distort_y);

    // Sample the texture normally + for RGB shift
    vec4 col_r = texture(TEXTURE, uv_distorted + vec2(rgb_shift_strength, 0.0));
    vec4 col_g = texture(TEXTURE, uv_distorted);
    vec4 col_b = texture(TEXTURE, uv_distorted - vec2(rgb_shift_strength, 0.0));

    // Combine channels for RGB glitch effect
    vec4 rgb_col = vec4(col_r.r, col_g.g, col_b.b, col_g.a);

    // Add horizontal scanline pattern
    float scanline = sin((uv.y + t * 5.0) * 200.0) * scanline_intensity;
    rgb_col.rgb += scanline * 0.1;

    COLOR = rgb_col;
}
