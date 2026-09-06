#extension GL_GOOGLE_include_directive : require

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform sampler2D input_image;

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;

layout(set = 0, binding = 5, rgba8) writeonly uniform image2D output_image;

#define amount ext.custom_uniforms[0].x
#define scale_value ext.custom_uniforms[0].y
#define speed ext.custom_uniforms[0].z
#define mix_amount ext.custom_uniforms[0].w

const float INV_255 = 1.0 / 255.0;

vec4 sample_clamped(vec2 uv) {
    return texture(input_image, clamp(uv, vec2(0.0), vec2(1.0)));
}

vec4 fetch_clamped(ivec2 pixel, ivec2 size) {
    return texelFetch(input_image, clamp(pixel, ivec2(0), size - ivec2(1)), 0);
}

uvec3 to_u8(vec3 color) {
    return uvec3(clamp(color * 255.0 + 0.5, 0.0, 255.0));
}

vec3 from_u8(uvec3 color) {
    return vec3(color & uvec3(255u)) * INV_255;
}

uvec3 rotate_left_8(uvec3 value, uint shift_value) {
    uint shift_count = shift_value & 7u;
    if (shift_count == 0u) {
        return value & uvec3(255u);
    }
    return ((value << shift_count) | (value >> (8u - shift_count))) &
           uvec3(255u);
}

float animated_phase() {
    return ext.u2.y * mix(0.25, 8.0, clamp(speed, 0.0, 1.0));
}

float random_hash(vec2 value, float seed) {
    return fract(sin(dot(value, vec2(12.9898, 78.233)) + seed * 37.719) *
                 43758.5453);
}

vec3 hsv_to_rgb(vec3 hsv) {
    vec3 value = clamp(abs(mod(hsv.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) -
                           1.0,
                       0.0, 1.0);
    return hsv.z * mix(vec3(1.0), value, hsv.y);
}

void main() {
    ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = imageSize(output_image);
    if (any(greaterThanEqual(pixel, size))) {
        return;
    }

    vec2 uv = (vec2(pixel) + vec2(0.5)) / vec2(size);
    vec4 source = texelFetch(input_image, pixel, 0);
    vec3 result = source.rgb;
    float strength = clamp(amount, 0.0, 1.0);
    float phase = animated_phase();

#if AC_EFFECT_ID == 0
    result = vec3(0.0);
#elif AC_EFFECT_ID == 1
    result = vec3(1.0) - source.rgb;
#elif AC_EFFECT_ID == 2
    result = vec3(dot(source.rgb, vec3(0.299, 0.587, 0.114)));
#elif AC_EFFECT_ID == 3
    result = source.rgb * mix(0.75, 0.1, strength);
#elif AC_EFFECT_ID == 4
    result = (vec3(1.0) - source.rgb) * mix(0.75, 0.2, strength);
#elif AC_EFFECT_ID == 5
    result = pow(max(source.rgb, vec3(0.0)), vec3(1.5));
#elif AC_EFFECT_ID == 6
    result = pow(max(source.rgb, vec3(0.0)), vec3(2.2));
#elif AC_EFFECT_ID == 7
    result = vec3(source.r, 0.0, 0.0);
#elif AC_EFFECT_ID == 8
    result = vec3(0.0, source.g, 0.0);
#elif AC_EFFECT_ID == 9
    result = vec3(0.0, 0.0, source.b);
#elif AC_EFFECT_ID == 10
    result = source.brg;
#elif AC_EFFECT_ID == 11
    int order_index = int(floor(mod(ext.u2.x, 6.0)));
    result = order_index == 0 ? source.rgb :
             order_index == 1 ? source.rbg :
             order_index == 2 ? source.grb :
             order_index == 3 ? source.gbr :
             order_index == 4 ? source.brg : source.bgr;
#elif AC_EFFECT_ID == 12
    result = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
#elif AC_EFFECT_ID == 13
    result = sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb;
#elif AC_EFFECT_ID == 14
    result = sample_clamped(vec2(1.0) - uv).rgb;
#elif AC_EFFECT_ID == 15
    vec2 mirror_uv = vec2(abs(uv.x * 2.0 - 1.0), uv.y);
    result = sample_clamped(mirror_uv).rgb;
#elif AC_EFFECT_ID == 16
    vec2 mirror_uv = vec2(1.0 - abs(uv.x * 2.0 - 1.0), uv.y);
    result = sample_clamped(mirror_uv).rgb;
#elif AC_EFFECT_ID == 17
    vec3 flipped = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    result = mix(source.rgb, flipped, 0.5);
#elif AC_EFFECT_ID == 18
    vec3 flipped = sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb;
    result = mix(source.rgb, flipped, 0.5);
#elif AC_EFFECT_ID == 19
    vec3 flipped = sample_clamped(vec2(1.0) - uv).rgb;
    result = mix(source.rgb, flipped, 0.5);
#elif AC_EFFECT_ID == 20
    float offset = mix(1.0, 24.0, clamp(scale_value, 0.0, 1.0)) / float(size.x);
    result = vec3(sample_clamped(uv + vec2(offset, 0.0)).r,
                  source.g,
                  sample_clamped(uv - vec2(offset, 0.0)).b);
#elif AC_EFFECT_ID == 21
    float offset = mix(1.0, 32.0, clamp(scale_value, 0.0, 1.0)) / float(size.x);
    result = vec3(sample_clamped(uv + vec2(offset, 0.0)).r,
                  sample_clamped(uv).g,
                  sample_clamped(uv - vec2(offset, 0.0)).b);
#elif AC_EFFECT_ID == 22
    int spacing = max(2, int(mix(2.0, 16.0, clamp(scale_value, 0.0, 1.0))));
    result = ((pixel.y / spacing) & 1) == 0 ? source.rgb : source.rgb * 0.25;
#elif AC_EFFECT_ID == 23
    int spacing = max(2, int(mix(2.0, 16.0, clamp(scale_value, 0.0, 1.0))));
    result = ((pixel.y / spacing) & 1) == 0 ? vec3(1.0) - source.rgb : source.rgb;
#elif AC_EFFECT_ID == 24
    int spacing = max(2, int(mix(2.0, 16.0, clamp(scale_value, 0.0, 1.0))));
    vec3 neighbor = fetch_clamped(pixel + ivec2(0, spacing), size).rgb;
    result = ((pixel.y / spacing) & 1) == 0 ? mix(source.rgb, neighbor, 0.5) : source.rgb;
#elif AC_EFFECT_ID == 25
    int spacing = max(2, int(mix(2.0, 18.0, clamp(scale_value, 0.0, 1.0))));
    result = ((pixel.y / spacing) & 1) == 0 ? source.rgb : vec3(0.0);
#elif AC_EFFECT_ID >= 26 && AC_EFFECT_ID <= 32
    int fixed_sizes[7] = int[7](4, 6, 8, 12, 16, 24, 32);
    int block_size = fixed_sizes[AC_EFFECT_ID - 26];
    ivec2 origin = (pixel / block_size) * block_size;
    result = fetch_clamped(origin, size).rgb;
#elif AC_EFFECT_ID == 33
    ivec2 block_size = ivec2(max(2, int(mix(3.0, 48.0, scale_value))),
                             max(2, int(mix(3.0, 32.0, amount))));
    result = fetch_clamped((pixel / block_size) * block_size, size).rgb;
#elif AC_EFFECT_ID == 34
    int block_size = max(2, int(mix(4.0, 64.0, scale_value)));
    ivec2 origin = (pixel / block_size) * block_size;
    vec3 block_color = fetch_clamped(origin, size).rgb;
    result = mix(source.rgb, block_color, 0.75);
#elif AC_EFFECT_ID == 35
    int block_size = max(2, int(mix(4.0, 64.0, scale_value)));
    uvec3 first = to_u8(source.rgb);
    uvec3 second = to_u8(fetch_clamped((pixel / block_size) * block_size, size).rgb);
    result = from_u8(first ^ second);
#elif AC_EFFECT_ID == 36
    int block_size = max(2, int(mix(4.0, 64.0, scale_value)));
    uvec3 block_color = to_u8(fetch_clamped((pixel / block_size) * block_size, size).rgb);
    result = from_u8(block_color * uint(1 + int(strength * 7.0)));
#elif AC_EFFECT_ID == 37
    int block_size = max(2, int(mix(4.0, 64.0, scale_value)));
    vec3 block_color = fetch_clamped((pixel / block_size) * block_size, size).rgb;
    result = sin(phase * 5.0) >= 0.0 ? block_color : vec3(1.0) - block_color;
#elif AC_EFFECT_ID == 38
    result = from_u8(to_u8(source.rgb) ^ uvec3(uint(1 + int(strength * 254.0))));
#elif AC_EFFECT_ID == 39
    result = from_u8(to_u8(source.rgb) & uvec3(uint(1 + int(strength * 254.0))));
#elif AC_EFFECT_ID == 40
    result = from_u8(to_u8(source.rgb) | uvec3(uint(1 + int(strength * 254.0))));
#elif AC_EFFECT_ID == 41
    result = from_u8(rotate_left_8(to_u8(source.rgb), uint(1 + int(strength * 7.0))));
#elif AC_EFFECT_ID == 42
    uvec3 original = to_u8(source.rgb);
    result = from_u8(original ^ rotate_left_8(original, uint(1 + int(strength * 7.0))));
#elif AC_EFFECT_ID == 43
    uvec3 original = to_u8(source.rgb);
    uvec3 scaled = original * uint(1 + int(strength * 7.0));
    result = from_u8(original ^ scaled);
#elif AC_EFFECT_ID == 44
    vec3 gradient = vec3(uv.x, uv.y, 1.0 - uv.x);
    result = mix(source.rgb, source.rgb * gradient * 1.8, strength);
#elif AC_EFFECT_ID == 45
    vec3 gradient = vec3(uv.x, 1.0 - uv.x, 0.5 + 0.5 * sin(phase));
    result = mix(source.rgb, gradient, strength);
#elif AC_EFFECT_ID == 46
    vec3 gradient = vec3(uv.y, 1.0 - uv.y, 0.5 + 0.5 * sin(phase + uv.y * 6.28318));
    result = mix(source.rgb, source.rgb * gradient * 2.0, strength);
#elif AC_EFFECT_ID == 47
    vec3 gradient = 0.5 + 0.5 * cos(phase + uv.xyx * 6.28318 + vec3(0.0, 2.094, 4.188));
    result = mix(source.rgb, gradient, strength);
#elif AC_EFFECT_ID == 48
    float level = mix(0.1, 0.9, strength);
    result = step(vec3(level), source.rgb);
#elif AC_EFFECT_ID == 49
    float level = mix(0.1, 0.9, strength);
    float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
    result = luminance < level ? vec3(0.0) : source.rgb;
#elif AC_EFFECT_ID == 50
    result = sin(phase * 4.0) >= 0.0 ? source.rgb : vec3(0.0);
#elif AC_EFFECT_ID == 51
    result = sin(phase * 4.0) >= 0.0 ? source.rgb : vec3(1.0);
#elif AC_EFFECT_ID == 52
    result = sin(phase * 4.0) >= 0.0 ? vec3(0.0) : vec3(1.0);
#elif AC_EFFECT_ID == 53
    int channel = int(floor(mod(ext.u2.x, 3.0)));
    result = channel == 0 ? vec3(source.r, 0.0, 0.0) :
             channel == 1 ? vec3(0.0, source.g, 0.0) :
                            vec3(0.0, 0.0, source.b);
#elif AC_EFFECT_ID == 54
    vec3 flash_color = 0.5 + 0.5 * cos(phase * 3.0 + vec3(0.0, 2.094, 4.188));
    result = source.rgb * flash_color * 1.8;
#elif AC_EFFECT_ID == 55
    float scan_position = fract(phase * 0.15) * float(size.y);
    float distance_value = abs(float(pixel.y) - scan_position);
    float band = 1.0 - smoothstep(0.0, mix(4.0, 80.0, scale_value), distance_value);
    result = mix(source.rgb * 0.25, source.rgb * 1.8, band);
#elif AC_EFFECT_ID == 56
    result = sin(phase * 5.0) >= 0.0 ? source.rgb : vec3(1.0) - source.rgb;
#elif AC_EFFECT_ID == 57
    float flash = step(0.0, sin(phase * 5.0));
    result = source.rgb * mix(0.65, 1.8, flash);
#elif AC_EFFECT_ID == 58
    float flash = step(0.0, sin(phase * 5.0));
    result = source.rgb * mix(0.12, 0.75, flash);
#elif AC_EFFECT_ID == 59
    float split = 0.5 + 0.35 * sin(phase);
    result = uv.x < split ? vec3(1.0) - source.rgb : source.rgb;
#elif AC_EFFECT_ID == 60
    float fade = 0.5 + 0.5 * sin(phase * 2.0);
    result = mix(source.rgb, vec3(1.0) - source.rgb, fade);
#elif AC_EFFECT_ID == 61
    vec3 mirror_color = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    result = sin(phase * 3.0) >= 0.0 ? source.rgb : mirror_color;
#elif AC_EFFECT_ID == 62
    uint mask_value = uint(1 + int((0.5 + 0.5 * sin(phase * 4.0)) * 254.0));
    result = from_u8(to_u8(source.rgb) & uvec3(mask_value));
#elif AC_EFFECT_ID == 63
    uint mask_value = uint(1 + int((0.5 + 0.5 * sin(phase * 4.0)) * 254.0));
    result = from_u8(to_u8(source.rgb) | uvec3(mask_value));
#elif AC_EFFECT_ID == 64
    float random_value = fract(sin(floor(ext.u2.x * 0.25) * 91.3458) * 47453.5453);
    result = random_value > 0.55 ? vec3(1.0) - source.rgb : source.rgb;
#elif AC_EFFECT_ID == 65
    float zoom = mix(0.72, 1.28, 0.5 + 0.5 * sin(phase * 2.0));
    vec2 sample_uv = (uv - 0.5) / zoom + 0.5;
    result = sample_clamped(sample_uv).rgb;
#elif AC_EFFECT_ID == 66
    vec3 flash_color = 0.5 + 0.5 * cos(phase * 2.5 + vec3(0.0, 2.094, 4.188));
    result = clamp(source.rgb + flash_color * strength, 0.0, 1.0);
#elif AC_EFFECT_ID == 67
    float wave = sin(uv.y * mix(12.0, 64.0, scale_value) + phase * 2.0);
    vec2 sample_uv = uv + vec2(wave * mix(0.005, 0.08, strength), 0.0);
    result = sample_clamped(sample_uv).rgb;
#elif AC_EFFECT_ID == 68
    float wave = sin(uv.y * mix(24.0, 120.0, scale_value) + phase * 4.0);
    vec2 sample_uv = uv + vec2(wave * mix(0.02, 0.18, strength), 0.0);
    result = sample_clamped(sample_uv).rgb;
#elif AC_EFFECT_ID == 69
    vec2 offset = vec2(mix(1.0, 40.0, scale_value) / float(size.x), 0.0);
    result = mix(sample_clamped(uv - offset).rgb,
                 sample_clamped(uv + offset).rgb, 0.5);
#elif AC_EFFECT_ID == 70
    float offset = mix(1.0, 48.0, scale_value) / float(size.x);
    result = vec3(sample_clamped(uv + vec2(offset, 0.0)).r,
                  sample_clamped(uv + vec2(0.0, offset)).g,
                  sample_clamped(uv - vec2(offset, 0.0)).b);
#elif AC_EFFECT_ID == 71
    float offset = sin(phase) * mix(0.02, 0.45, strength);
    result = sample_clamped(vec2(fract(uv.x + offset), uv.y)).rgb;
#elif AC_EFFECT_ID == 72
    float offset = sin(phase) * mix(0.02, 0.45, strength);
    result = sample_clamped(vec2(uv.x, fract(uv.y + offset))).rgb;
#elif AC_EFFECT_ID == 73
    vec2 centered = uv - 0.5;
    float zoom = mix(1.0, 0.45, strength * (0.5 + 0.5 * sin(phase)));
    result = sample_clamped(centered * zoom + 0.5).rgb;
#elif AC_EFFECT_ID == 74
    vec2 centered = uv - 0.5;
    float edge = max(abs(centered.x), abs(centered.y));
    float push = sin(edge * mix(12.0, 50.0, scale_value) - phase) * strength * 0.08;
    result = sample_clamped(centered * (1.0 + push) + 0.5).rgb;
#elif AC_EFFECT_ID == 75
    int band_size = max(2, int(mix(3.0, 40.0, scale_value)));
    int shift = int(sin(float(pixel.y / band_size) + phase) * strength * float(size.x) * 0.2);
    result = fetch_clamped(pixel + ivec2(shift, 0), size).rgb;
#elif AC_EFFECT_ID == 76
    int band_size = max(2, int(mix(3.0, 40.0, scale_value)));
    int shift = int(sin(float(pixel.x / band_size) + phase) * strength * float(size.y) * 0.2);
    result = fetch_clamped(pixel + ivec2(0, shift), size).rgb;
#elif AC_EFFECT_ID == 77
    float line_value = step(0.72, fract((uv.x + uv.y) * mix(8.0, 64.0, scale_value) + phase));
    result = mix(source.rgb * 0.35, source.rgb * 1.6, line_value);
#elif AC_EFFECT_ID == 78
    float line_value = step(0.72, fract(uv.y * mix(8.0, 80.0, scale_value) + phase));
    result = mix(source.rgb * 0.35, source.rgb * 1.6, line_value);
#elif AC_EFFECT_ID == 79
    float x_line = step(0.82, fract(uv.x * mix(8.0, 64.0, scale_value) + phase));
    float y_line = step(0.82, fract(uv.y * mix(8.0, 64.0, scale_value) - phase));
    result = source.rgb * mix(0.35, 1.7, max(x_line, y_line));
#elif AC_EFFECT_ID == 80
    float line_value = step(0.9, fract(uv.y * mix(10.0, 90.0, scale_value) + phase));
    result = mix(source.rgb, vec3(1.0), line_value);
#elif AC_EFFECT_ID == 81
    float line_value = step(0.58, fract(uv.y * mix(5.0, 36.0, scale_value) + phase));
    result = mix(source.rgb, vec3(1.0), line_value);
#elif AC_EFFECT_ID == 82
    float line_value = fract((uv.x + uv.y) * mix(4.0, 40.0, scale_value) + phase * 0.5);
    vec3 gradient = 0.5 + 0.5 * cos(line_value * 6.28318 + vec3(0.0, 2.094, 4.188));
    result = mix(source.rgb, source.rgb * gradient * 1.8, strength);
#elif AC_EFFECT_ID == 83
    vec3 gradient = vec3(uv.x, 1.0 - uv.x, 0.5 + 0.5 * sin(phase));
    result = mix(source.rgb, source.rgb * gradient * 2.0, strength);
#elif AC_EFFECT_ID == 84
    vec3 gradient = vec3(uv.y, 1.0 - uv.y, 0.5 + 0.5 * cos(phase));
    result = mix(source.rgb, source.rgb * gradient * 2.0, strength);
#elif AC_EFFECT_ID == 85
    float stripe = step(0.5, fract(uv.y * mix(4.0, 48.0, scale_value) + phase * 0.4));
    vec3 palette = 0.5 + 0.5 * cos(phase + vec3(0.0, 2.094, 4.188));
    result = mix(source.rgb, source.rgb * mix(vec3(0.35), palette * 1.7, stripe), strength);
#elif AC_EFFECT_ID == 86
    vec3 gradient = vec3(1.0 - uv.x, uv.x, 1.0 - uv.y);
    result = mix(source.rgb, source.rgb * gradient * 1.8, strength);
#elif AC_EFFECT_ID == 87
    vec3 gradient = vec3(1.0 - uv.y, uv.y, uv.x);
    result = mix(source.rgb, source.rgb * gradient * 1.8, strength);
#elif AC_EFFECT_ID == 88
    vec2 cell = abs(fract(uv * mix(3.0, 18.0, scale_value)) - 0.5) * 2.0;
    float box_gradient = max(cell.x, cell.y);
    result = mix(source.rgb, source.rgb * (1.5 - box_gradient), strength);
#elif AC_EFFECT_ID == 89
    vec3 palette = 0.5 + 0.5 * cos(phase + uv.xyx * 8.0 + vec3(0.0, 2.094, 4.188));
    result = mix(source.rgb, source.rgb * palette * 1.9, strength);
#elif AC_EFFECT_ID == 90
    float gradient = 1.0 - abs(uv.x * 2.0 - 1.0);
    gradient *= 0.65 + 0.35 * sin(phase);
    result = mix(source.rgb, source.rgb * gradient * 2.0, strength);
#elif AC_EFFECT_ID == 91
    float gradient = 1.0 - abs(uv.y * 2.0 - 1.0);
    gradient *= 0.65 + 0.35 * cos(phase);
    result = mix(source.rgb, source.rgb * gradient * 2.0, strength);
#elif AC_EFFECT_ID == 92
    int block_size = max(2, int(mix(4.0, 48.0, scale_value)));
    ivec2 origin = (pixel / block_size) * block_size;
    ivec2 sample_pixel = ((pixel.y / block_size) & 1) == 0 ? origin : ivec2(size.x - 1 - origin.x, origin.y);
    result = fetch_clamped(sample_pixel, size).rgb;
#elif AC_EFFECT_ID == 93
    int block_size = 8;
    ivec2 origin = (pixel / block_size) * block_size;
    ivec2 sample_pixel = ((pixel.y / block_size) & 1) == 0 ? origin : ivec2(size.x - 1 - origin.x, origin.y);
    result = fetch_clamped(sample_pixel, size).rgb;
#elif AC_EFFECT_ID == 94
    int band = 8;
    vec2 sample_uv = ((pixel.x / band) & 1) == 0 ? uv : vec2(uv.x, 1.0 - uv.y);
    result = sample_clamped(sample_uv).rgb;
#elif AC_EFFECT_ID == 95
    int band = 16;
    vec2 sample_uv = ((pixel.x / band) & 1) == 0 ? uv : vec2(uv.x, 1.0 - uv.y);
    result = sample_clamped(sample_uv).rgb;
#elif AC_EFFECT_ID == 96
    ivec2 origin = (pixel / 8) * 8;
    result = fetch_clamped(origin, size).rgb;
#elif AC_EFFECT_ID == 97
    ivec2 origin = (pixel / 16) * 16;
    result = fetch_clamped(origin, size).rgb;
#elif AC_EFFECT_ID == 98
    ivec2 origin = (pixel / 8) * 8;
    result = mix(source.rgb, fetch_clamped(origin, size).rgb, 0.5);
#elif AC_EFFECT_ID == 99
    vec2 centered = uv - 0.5;
    float radius = length(centered);
    float angle = atan(centered.y, centered.x);
    angle += sin(radius * mix(12.0, 54.0, scale_value) - phase) * strength;
    vec2 sample_uv = vec2(cos(angle), sin(angle)) * radius + 0.5;
    result = sample_clamped(sample_uv).rgb;
#elif AC_EFFECT_ID == 100
    int radius = max(1, int(mix(1.0, 12.0, scale_value)));
    vec3 nearby = fetch_clamped(pixel + ivec2(radius, radius), size).rgb;
    result = mix(source.rgb, nearby, strength);
#elif AC_EFFECT_ID == 101
    uint multiplier = uint(1 + int(strength * 15.0));
    result = from_u8(to_u8(source.rgb) * multiplier);
#elif AC_EFFECT_ID == 102
    vec3 horizontal = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    vec3 vertical = sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb;
    result = (source.rgb + horizontal + vertical) / 3.0;
#elif AC_EFFECT_ID == 103
    vec3 mirrored = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    result = mix(source.rgb, mirrored, strength);
#elif AC_EFFECT_ID == 104
    vec3 mirrored = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    result = (source.rgb + mirrored) * 0.5;
#elif AC_EFFECT_ID == 105
    vec3 horizontal = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    vec3 vertical = sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb;
    result = mix(source.rgb, (horizontal + vertical) * 0.5, strength);
#elif AC_EFFECT_ID == 106
    int offset = int(sin(phase) * mix(1.0, 40.0, scale_value));
    result = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                  source.g, source.b);
#elif AC_EFFECT_ID == 107
    int offset = int(sin(phase) * mix(1.0, 40.0, scale_value));
    result = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                  fetch_clamped(pixel + ivec2(0, offset), size).g,
                  fetch_clamped(pixel - ivec2(offset, 0), size).b);
#elif AC_EFFECT_ID == 108
    int offset = int(sin(phase) * mix(1.0, 48.0, scale_value));
    result = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                  fetch_clamped(pixel + ivec2(offset / 2, offset / 2), size).g,
                  fetch_clamped(pixel + ivec2(0, offset), size).b);
#elif AC_EFFECT_ID == 109
    int distance_value = max(1, int(mix(1.0, 32.0, scale_value)));
    vec3 neighbor = fetch_clamped(pixel + ivec2(distance_value, 0), size).rgb;
    result = mix(source.rgb, neighbor, strength);
#elif AC_EFFECT_ID == 110
    int distance_value = max(1, int(mix(1.0, 32.0, scale_value)));
    vec3 neighbor = fetch_clamped(pixel + ivec2(0, distance_value), size).rgb;
    result = mix(source.rgb, neighbor, strength);
#elif AC_EFFECT_ID == 111
    vec3 opposite = sample_clamped(vec2(1.0) - uv).rgb;
    result = mix(source.rgb, opposite, strength);
#elif AC_EFFECT_ID == 112
    vec3 mirrored = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    float edge_mix = smoothstep(0.0, mix(0.05, 0.45, scale_value), abs(uv.x - 0.5));
    result = mix(source.rgb, mirrored, edge_mix * strength);
#elif AC_EFFECT_ID == 113
    vec3 palette = 0.5 + 0.5 * cos(phase + source.rgb * 6.28318 + vec3(0.0, 2.094, 4.188));
    result = mix(source.rgb, palette, strength);
#elif AC_EFFECT_ID == 114
    int channel = (pixel.y / max(1, int(mix(2.0, 18.0, scale_value)))) % 3;
    result = channel == 0 ? vec3(source.r, 0.0, 0.0) :
             channel == 1 ? vec3(0.0, source.g, 0.0) :
                            vec3(0.0, 0.0, source.b);
#elif AC_EFFECT_ID == 115
    int channel = (pixel.x + pixel.y) % 3;
    result = channel == 0 ? vec3(source.r, 0.0, 0.0) :
             channel == 1 ? vec3(0.0, source.g, 0.0) :
                            vec3(0.0, 0.0, source.b);
#elif AC_EFFECT_ID == 116
    int block_size = max(2, int(mix(4.0, 48.0, scale_value)));
    ivec2 cell = pixel / block_size;
    int channel = (cell.x + cell.y) % 3;
    result = channel == 0 ? vec3(source.r, 0.0, 0.0) :
             channel == 1 ? vec3(0.0, source.g, 0.0) :
                            vec3(0.0, 0.0, source.b);
#elif AC_EFFECT_ID == 117
    float levels = floor(mix(2.0, 24.0, scale_value));
    result = floor(source.rgb * levels) / max(levels - 1.0, 1.0);
#elif AC_EFFECT_ID == 118
    int band_size = max(1, int(mix(2.0, 32.0, scale_value)));
    vec3 mirrored = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    result = ((pixel.y / band_size) & 1) == 0 ? source.rgb : mirrored;
#elif AC_EFFECT_ID == 119
    int block_size = max(2, int(mix(4.0, 48.0, scale_value)));
    ivec2 cell = pixel / block_size;
    vec2 mirror_uv = vec2((cell.x & 1) == 0 ? uv.x : 1.0 - uv.x,
                           (cell.y & 1) == 0 ? uv.y : 1.0 - uv.y);
    result = sample_clamped(mirror_uv).rgb;
#elif AC_EFFECT_ID == 120
    vec3 horizontal = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    vec3 vertical = sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb;
    result = vec3(horizontal.r, vertical.g, source.b);
#elif AC_EFFECT_ID == 121
    int radius = max(1, int(mix(1.0, 24.0, scale_value)));
    vec3 above = fetch_clamped(pixel - ivec2(0, radius), size).rgb;
    vec3 below = fetch_clamped(pixel + ivec2(0, radius), size).rgb;
    result = (above + source.rgb + below) / 3.0;
#elif AC_EFFECT_ID == 122
    vec3 horizontal = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    vec3 vertical = sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb;
    result = vec3(horizontal.r, source.g, vertical.b);
#elif AC_EFFECT_ID == 123
    vec3 opposite = sample_clamped(vec2(1.0) - uv).rgb;
    float random_value = fract(sin(dot(floor(vec2(pixel) / 8.0), vec2(12.9898, 78.233)) + floor(ext.u2.x)) * 43758.5453);
    result = from_u8(to_u8(source.rgb) ^ to_u8(opposite * random_value));
#elif AC_EFFECT_ID == 124
    float random_value = fract(sin(floor(ext.u2.x * 0.2) * 71.735) * 43758.5453);
    vec2 mirror_uv = random_value < 0.5 ? vec2(1.0 - uv.x, uv.y) : vec2(uv.x, 1.0 - uv.y);
    result = sample_clamped(mirror_uv).rgb;
#elif AC_EFFECT_ID == 125
    float random_value = fract(sin(floor(ext.u2.x * 0.2) * 71.735) * 43758.5453);
    vec2 mirror_uv = random_value < 0.5 ? vec2(1.0 - uv.x, uv.y) : vec2(uv.x, 1.0 - uv.y);
    result = mix(source.rgb, sample_clamped(mirror_uv).rgb, strength);
#elif AC_EFFECT_ID == 126
    float random_value = fract(sin(floor(ext.u2.x * 0.2) * 71.735) * 43758.5453);
    vec2 mirror_uv = random_value < 0.5 ? vec2(1.0 - uv.x, uv.y) : vec2(uv.x, 1.0 - uv.y);
    result = mix(source.rgb, sample_clamped(mirror_uv).rgb, 0.2 + 0.8 * random_value);
#elif AC_EFFECT_ID == 127
    uvec3 original = to_u8(source.rgb);
    uvec3 mirrored = to_u8(sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb);
    result = from_u8(original ^ mirrored);
#elif AC_EFFECT_ID == 128
    uvec3 original = to_u8(source.rgb);
    uvec3 horizontal = to_u8(sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb);
    uvec3 vertical = to_u8(sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb);
    result = from_u8(original ^ horizontal ^ vertical);
#elif AC_EFFECT_ID == 129
    uvec3 original = to_u8(source.rgb);
    uvec3 mirrored = to_u8(sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb);
    result = from_u8(original ^ (mirrored * uint(1 + int(strength * 7.0))));
#elif AC_EFFECT_ID == 130
    vec3 mirrored = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    result = clamp(abs(source.rgb - mirrored) * mix(1.0, 4.0, strength), 0.0, 1.0);
#elif AC_EFFECT_ID == 131
    uvec3 original = to_u8(source.rgb);
    uvec3 mirrored = to_u8(sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb);
    result = mix(source.rgb, from_u8(original ^ mirrored), strength);
#elif AC_EFFECT_ID == 132
    vec2 mirror_uv = uv.x < 0.5 ? vec2(uv.x, 1.0 - uv.y) : vec2(1.0 - uv.x, uv.y);
    result = sample_clamped(mirror_uv).rgb;
#elif AC_EFFECT_ID == 133
    vec3 first = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    vec3 second = sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb;
    result = (source.rgb + first + second) / 3.0;
#elif AC_EFFECT_ID == 134
    vec3 boosted = clamp(source.rgb * mix(0.5, 2.0, scale_value), 0.0, 1.0);
    result = mix(source.rgb, boosted, strength);
#elif AC_EFFECT_ID == 135
    vec3 mirrored = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    result = vec3(mirrored.b, source.g, mirrored.r);
#elif AC_EFFECT_ID == 136
    vec3 mirrored = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    result = sin(phase * 4.0) >= 0.0 ? mirrored : vec3(1.0) - mirrored;
#elif AC_EFFECT_ID == 137
    vec2 reverse_uv = vec2(1.0 - uv.x, 1.0 - abs(uv.y * 2.0 - 1.0));
    result = sample_clamped(reverse_uv).rgb;
#elif AC_EFFECT_ID == 138
    uvec3 original = to_u8(source.rgb);
    uvec3 reverse_color = to_u8(sample_clamped(vec2(1.0) - uv).rgb);
    uvec3 mirror_color = to_u8(sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb);
    result = from_u8(original ^ reverse_color ^ mirror_color);
#elif AC_EFFECT_ID == 139
    vec3 mirrored = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    result = mirrored.bgr;
#elif AC_EFFECT_ID == 140
    vec3 mirrored = sample_clamped(vec2(1.0 - uv.x, uv.y)).bgr;
    result = mix(source.rgb, mirrored, strength);
#elif AC_EFFECT_ID == 141
    uvec3 mirrored = to_u8(sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb);
    result = from_u8(to_u8(source.rgb) ^ rotate_left_8(mirrored, uint(1 + int(strength * 7.0))));
#elif AC_EFFECT_ID == 142
    vec3 horizontal = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    vec3 vertical = sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb;
    result = mix(source.rgb, mix(horizontal, vertical, 0.5), strength);
#elif AC_EFFECT_ID == 143
    vec2 centered = uv - 0.5;
    float angle = atan(centered.y, centered.x) + sin(length(centered) * 24.0 - phase) * strength;
    vec2 twisted = vec2(cos(angle), sin(angle)) * length(centered) + 0.5;
    twisted.x = 1.0 - twisted.x;
    result = sample_clamped(twisted).rgb;
#elif AC_EFFECT_ID == 144
    vec2 flip_uv = sin(phase) >= 0.0 ? vec2(1.0 - uv.x, uv.y) : vec2(uv.x, 1.0 - uv.y);
    result = mix(source.rgb, sample_clamped(flip_uv).rgb, strength);
#elif AC_EFFECT_ID == 145
    int radius = max(1, int(mix(1.0, 8.0, scale_value)));
    vec3 a = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    vec3 b = fetch_clamped(pixel + ivec2(radius, 0), size).rgb;
    vec3 c = fetch_clamped(pixel - ivec2(radius, 0), size).rgb;
    result = a + b + c - min(a, min(b, c)) - max(a, max(b, c));
#elif AC_EFFECT_ID == 146
    vec3 horizontal = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    vec3 vertical = sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb;
    result = mix(source.rgb, (horizontal + vertical) * 0.5, strength);
#elif AC_EFFECT_ID == 147
    int mode = int(floor(mod(ext.u2.y, 4.0)));
    vec2 mirror_uv = mode == 0 ? uv :
                     mode == 1 ? vec2(1.0 - uv.x, uv.y) :
                     mode == 2 ? vec2(uv.x, 1.0 - uv.y) : vec2(1.0) - uv;
    result = sample_clamped(mirror_uv).rgb;
#elif AC_EFFECT_ID == 148
    uvec3 horizontal = to_u8(sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb);
    uvec3 vertical = to_u8(sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb);
    result = from_u8(to_u8(source.rgb) ^ ((horizontal + vertical) / 2u));
#elif AC_EFFECT_ID == 149
    vec3 horizontal = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    vec3 vertical = sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb;
    vec3 both = sample_clamped(vec2(1.0) - uv).rgb;
    result = (source.rgb + horizontal + vertical + both) * 0.25;
#elif AC_EFFECT_ID == 150
    float frequency = mix(3.0, 18.0, scale_value);
    vec3 triangle = abs(fract(vec3(uv.x, uv.y, uv.x + uv.y) * frequency +
                              phase * vec3(0.11, -0.08, 0.05)) *
                                2.0 -
                            1.0);
    result = mix(source.rgb, source.rgb * (0.35 + triangle), strength);
#elif AC_EFFECT_ID == 151
    float distortion = mix(0.005, 0.12, scale_value) * strength;
    vec2 sample_uv = uv + vec2(sin(uv.y * 31.0 + phase),
                               cos(uv.x * 27.0 - phase * 0.8)) *
                              distortion;
    result = sample_clamped(sample_uv).rgb;
#elif AC_EFFECT_ID == 152
    vec3 multiplier = 0.5 + 0.5 * vec3(cos(phase + uv.x * 12.0),
                                        sin(phase * 0.83 + uv.y * 15.0),
                                        cos(phase * 0.61 + (uv.x + uv.y) * 9.0));
    result = mix(source.rgb, source.rgb * multiplier * 1.6, strength);
#elif AC_EFFECT_ID == 153
    int block_size = max(2, int(mix(3.0, 72.0, scale_value) *
                                (0.55 + 0.45 * abs(sin(phase)))));
    result = fetch_clamped((pixel / block_size) * block_size, size).rgb;
#elif AC_EFFECT_ID == 154
    float cells = mix(4.0, 32.0, scale_value);
    vec2 cell_uv = fract(uv * cells);
    float border = 1.0 - smoothstep(0.03, 0.12,
                                    min(min(cell_uv.x, 1.0 - cell_uv.x),
                                        min(cell_uv.y, 1.0 - cell_uv.y)));
    result = mix(source.rgb, vec3(1.0) - source.rgb, border * strength);
#elif AC_EFFECT_ID == 155
    float cells = mix(4.0, 30.0, scale_value);
    vec2 cell_uv = fract(uv * cells);
    float edge = min(min(cell_uv.x, 1.0 - cell_uv.x),
                     min(cell_uv.y, 1.0 - cell_uv.y));
    float border = 1.0 - smoothstep(0.02, 0.16, edge);
    float fade = 0.5 + 0.5 * sin(phase + floor(uv.x * cells) +
                                 floor(uv.y * cells) * 0.73);
    result = mix(source.rgb, vec3(fade), border * strength);
#elif AC_EFFECT_ID == 156
    float seed = dot(vec2(pixel), vec2(12.9898, 78.233)) + floor(phase * 8.0);
    float random_value = fract(sin(seed) * 43758.5453);
    float threshold = mix(0.995, 0.92, scale_value) * mix(1.0, 0.92, strength);
    result = random_value > threshold ? vec3(1.0) : source.rgb;
#elif AC_EFFECT_ID == 157
    vec2 tile_uv = fract(uv * 2.0);
    tile_uv = vec2(tile_uv.x > 0.5 ? 1.0 - tile_uv.x : tile_uv.x,
                   tile_uv.y > 0.5 ? 1.0 - tile_uv.y : tile_uv.y) * 2.0;
    result = sample_clamped(tile_uv).rgb;
#elif AC_EFFECT_ID == 158
    vec2 tile_uv = fract(uv * vec2(4.0, 2.0));
    ivec2 tile = ivec2(floor(uv * vec2(4.0, 2.0)));
    if (((tile.x + tile.y) & 1) != 0) {
        tile_uv = vec2(1.0) - tile_uv;
    }
    result = sample_clamped(tile_uv).rgb;
#elif AC_EFFECT_ID == 159
    int block_size = max(3, int(mix(6.0, 64.0, scale_value)));
    ivec2 cell = pixel / block_size;
    int offset = int(sin(phase + float(cell.x + cell.y)) * float(block_size));
    result = fetch_clamped(pixel + ivec2(offset, offset), size).rgb;
#elif AC_EFFECT_ID == 160
    int block_size = max(3, int(mix(6.0, 64.0, scale_value)));
    ivec2 cell = pixel / block_size;
    float random_value = fract(sin(dot(vec2(cell), vec2(91.17, 37.43)) +
                                   floor(phase * 3.0)) *
                                  43758.5453);
    int offset = int((random_value * 2.0 - 1.0) * float(block_size));
    result = fetch_clamped(pixel + ivec2(offset, offset), size).rgb;
#elif AC_EFFECT_ID == 161
    int band = max(4, int(mix(8.0, 80.0, scale_value)));
    int offset = int((0.5 + 0.5 * sin(phase + float(pixel.x / band))) *
                     float(band) * strength);
    result = fetch_clamped(pixel + ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 162
    int band = max(4, int(mix(8.0, 80.0, scale_value)));
    int offset = int((0.5 + 0.5 * sin(phase + float(pixel.y / band))) *
                     float(band) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 163
    int band = max(4, int(mix(8.0, 80.0, scale_value)));
    int offset = int((0.5 + 0.5 * sin(phase + float(pixel.x / band))) *
                     float(band) * strength);
    result = fetch_clamped(pixel - ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 164
    int band = max(4, int(mix(8.0, 80.0, scale_value)));
    int offset = int((0.5 + 0.5 * sin(phase + float(pixel.y / band))) *
                     float(band) * strength);
    result = fetch_clamped(pixel - ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 165
    ivec2 quadrant = ivec2(uv * 2.0);
    vec2 local_uv = fract(uv * 2.0);
    float random_value = fract(sin(dot(vec2(quadrant), vec2(43.17, 89.31)) +
                                   floor(phase)) *
                                  43758.5453);
    if (random_value < 0.33) {
        local_uv.x = 1.0 - local_uv.x;
    } else if (random_value < 0.66) {
        local_uv.y = 1.0 - local_uv.y;
    } else {
        local_uv = vec2(1.0) - local_uv;
    }
    result = sample_clamped(local_uv).rgb;
#elif AC_EFFECT_ID == 166
    int block_size = max(4, int(mix(8.0, 96.0, scale_value)));
    ivec2 cell = pixel / block_size;
    float random_value = fract(sin(dot(vec2(cell), vec2(12.9898, 78.233)) +
                                   floor(phase * 2.0)) *
                                  43758.5453);
    ivec2 offset = ivec2(int((random_value - 0.5) * float(block_size) * 2.0),
                         int((fract(random_value * 17.0) - 0.5) *
                             float(block_size) * 2.0));
    result = fetch_clamped(pixel + offset, size).rgb;
#elif AC_EFFECT_ID == 167
    int block_size = max(3, int(mix(5.0, 64.0, scale_value)));
    ivec2 cell = pixel / block_size;
    float random_value = fract(sin(dot(vec2(cell), vec2(26.651, 47.773)) +
                                   floor(phase * 4.0)) *
                                  43758.5453);
    ivec2 origin = cell * block_size;
    vec3 cell_color = fetch_clamped(origin + ivec2(random_value * float(block_size)), size).rgb;
    result = mix(source.rgb, cell_color, step(0.5, random_value) * strength);
#elif AC_EFFECT_ID == 168
    float folds = mix(4.0, 24.0, scale_value);
    float wave = sin(uv.y * folds * 6.28318 + phase);
    result = sample_clamped(vec2(uv.x + wave * 0.06 * strength, uv.y)).rgb;
#elif AC_EFFECT_ID == 169
    float folds = mix(4.0, 28.0, scale_value);
    float row = floor(uv.y * folds);
    float random_value = fract(sin(row * 91.731 + floor(phase * 2.0)) * 43758.5453);
    result = sample_clamped(vec2(uv.x + (random_value - 0.5) * 0.22 * strength,
                                 uv.y)).rgb;
#elif AC_EFFECT_ID == 170
    float folds = mix(4.0, 24.0, scale_value);
    float wave = sin(uv.x * folds * 6.28318 + phase);
    result = sample_clamped(vec2(uv.x, uv.y + wave * 0.06 * strength)).rgb;
#elif AC_EFFECT_ID == 171
    float folds = mix(4.0, 28.0, scale_value);
    float column = floor(uv.x * folds);
    float random_value = fract(sin(column * 91.731 + floor(phase * 2.0)) * 43758.5453);
    result = sample_clamped(vec2(uv.x,
                                 uv.y + (random_value - 0.5) * 0.22 * strength)).rgb;
#elif AC_EFFECT_ID == 172
    int band_size = max(2, int(mix(4.0, 48.0, scale_value)));
    float direction = ((pixel.y / band_size) & 1) == 0 ? 1.0 : -1.0;
    result = sample_clamped(fract(uv + vec2(direction * phase * 0.04 * strength, 0.0))).rgb;
#elif AC_EFFECT_ID == 173
    int band_size = max(2, int(mix(4.0, 48.0, scale_value)));
    float direction = ((pixel.y / band_size) & 1) == 0 ? 1.0 : -1.0;
    vec3 shifted = sample_clamped(fract(uv + vec2(direction * phase * 0.04 * strength, 0.0))).rgb;
    result = from_u8(to_u8(source.rgb) ^ to_u8(shifted));
#elif AC_EFFECT_ID == 174
    int band_size = max(2, int(mix(4.0, 48.0, scale_value)));
    int band = pixel.y / band_size;
    float random_value = fract(sin(float(band) * 73.19 + floor(phase)) * 43758.5453);
    result = sample_clamped(fract(uv + vec2((random_value - 0.5) * strength, 0.0))).rgb;
#elif AC_EFFECT_ID == 175
    int band_size = max(2, int(mix(4.0, 48.0, scale_value)));
    float direction = ((pixel.x / band_size) & 1) == 0 ? 1.0 : -1.0;
    result = sample_clamped(fract(uv + vec2(0.0, direction * phase * 0.04 * strength))).rgb;
#elif AC_EFFECT_ID == 176
    int band_size = max(2, int(mix(4.0, 48.0, scale_value)));
    float direction = ((pixel.x / band_size) & 1) == 0 ? 1.0 : -1.0;
    vec3 shifted = sample_clamped(fract(uv + vec2(0.0, direction * phase * 0.04 * strength))).rgb;
    result = from_u8(to_u8(source.rgb) ^ to_u8(shifted));
#elif AC_EFFECT_ID == 177
    int band_size = max(2, int(mix(4.0, 48.0, scale_value)));
    int band = pixel.x / band_size;
    float random_value = fract(sin(float(band) * 73.19 + floor(phase)) * 43758.5453);
    result = sample_clamped(fract(uv + vec2(0.0, (random_value - 0.5) * strength))).rgb;
#elif AC_EFFECT_ID == 178
    vec2 centered = uv - 0.5;
    vec2 stretched = centered * (1.0 - 0.35 * strength * sin(phase)) + 0.5;
    result = sample_clamped(stretched).rgb;
#elif AC_EFFECT_ID == 179
    float zoom = 1.0 + mix(0.02, 0.45, scale_value) *
                             (0.5 + 0.5 * sin(phase)) * strength;
    result = sample_clamped((uv - 0.5) / zoom + 0.5).rgb;
#elif AC_EFFECT_ID == 180
    float angle = phase * mix(0.05, 0.5, scale_value);
    float cosine_value = cos(angle);
    float sine_value = sin(angle);
    vec2 rotated = mat2(cosine_value, -sine_value, sine_value, cosine_value) *
                       (uv - 0.5) +
                   0.5;
    result = sample_clamped(rotated).rgb;
#elif AC_EFFECT_ID == 181
    float angle = -phase * mix(0.05, 0.5, scale_value);
    float cosine_value = cos(angle);
    float sine_value = sin(angle);
    vec2 rotated = mat2(cosine_value, -sine_value, sine_value, cosine_value) *
                       (uv - 0.5) +
                   0.5;
    result = sample_clamped(rotated).rgb;
#elif AC_EFFECT_ID == 182
    float angle = floor(phase * mix(0.25, 1.0, scale_value)) * 1.5707963;
    float cosine_value = cos(angle);
    float sine_value = sin(angle);
    vec2 rotated = mat2(cosine_value, -sine_value, sine_value, cosine_value) *
                       (uv - 0.5) +
                   0.5;
    result = sample_clamped(rotated).rgb;
#elif AC_EFFECT_ID == 183
    float angle = -floor(phase * mix(0.25, 1.0, scale_value)) * 1.5707963;
    float cosine_value = cos(angle);
    float sine_value = sin(angle);
    vec2 rotated = mat2(cosine_value, -sine_value, sine_value, cosine_value) *
                       (uv - 0.5) +
                   0.5;
    result = sample_clamped(rotated).rgb;
#elif AC_EFFECT_ID == 184
    float blocks = mix(20.0, 180.0, scale_value);
    vec2 expanded = (uv - 0.5) * (1.0 - 0.25 * sin(phase) * strength) + 0.5;
    vec2 pixel_uv = (floor(expanded * blocks) + 0.5) / blocks;
    result = sample_clamped(pixel_uv).rgb;
#elif AC_EFFECT_ID == 185
    float blocks = mix(20.0, 180.0, scale_value);
    vec2 expanded = vec2((uv.x - 0.5) * (1.0 - 0.4 * sin(phase) * strength) + 0.5,
                         uv.y);
    result = sample_clamped((floor(expanded * blocks) + 0.5) / blocks).rgb;
#elif AC_EFFECT_ID == 186
    float blocks = mix(20.0, 180.0, scale_value);
    vec2 expanded = vec2(uv.x,
                         (uv.y - 0.5) * (1.0 - 0.4 * sin(phase) * strength) + 0.5);
    result = sample_clamped((floor(expanded * blocks) + 0.5) / blocks).rgb;
#elif AC_EFFECT_ID == 187
    float blocks = mix(16.0, 140.0, scale_value);
    vec2 expanded = (uv - 0.5) * (1.0 - 0.3 * cos(phase) * strength) + 0.5;
    expanded += vec2(sin(uv.y * 30.0 + phase), cos(uv.x * 27.0 - phase)) *
                0.04 * strength;
    result = sample_clamped((floor(expanded * blocks) + 0.5) / blocks).rgb;
#elif AC_EFFECT_ID == 188
    float blocks = mix(18.0, 160.0, scale_value);
    vec2 distorted = uv + vec2(sin(uv.y * 24.0 + phase),
                               cos(uv.x * 21.0 - phase)) *
                              0.06 * strength;
    result = sample_clamped((floor(distorted * blocks) + 0.5) / blocks).rgb;
#elif AC_EFFECT_ID == 189
    int small_block = max(2, int(mix(3.0, 18.0, scale_value)));
    int large_block = small_block * 4;
    ivec2 cell = pixel / large_block;
    int block_size = ((cell.x + cell.y) & 1) == 0 ? small_block : large_block;
    result = fetch_clamped((pixel / block_size) * block_size, size).rgb;
#elif AC_EFFECT_ID == 190
    int distance_value = max(1, int(mix(2.0, 60.0, scale_value)));
    int offset = int(sin(phase + float(pixel.x + pixel.y) * 0.02) *
                     float(distance_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, offset), size).rgb;
#elif AC_EFFECT_ID == 191
    int distance_value = max(1, int(mix(2.0, 60.0, scale_value)));
    int offset = int(sin(phase + float(pixel.x) * 0.025) *
                     float(distance_value) * strength);
    result = fetch_clamped(pixel + ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 192
    int distance_value = max(1, int(mix(2.0, 70.0, scale_value)));
    float direction = ((pixel.x / max(1, distance_value)) & 1) == 0 ? 1.0 : -1.0;
    int offset = int(direction * sin(phase + float(pixel.x) * 0.02) *
                     float(distance_value) * strength);
    result = fetch_clamped(pixel + ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 193
    int distance_value = max(1, int(mix(2.0, 72.0, scale_value)));
    int first_offset = int(sin(phase + float(pixel.x) * 0.02) *
                           float(distance_value) * strength);
    int second_offset = int(cos(phase * 0.7 + float(pixel.y) * 0.03) *
                            float(distance_value) * 0.5 * strength);
    vec3 first = fetch_clamped(pixel + ivec2(second_offset, first_offset), size).rgb;
    vec3 second = fetch_clamped(pixel - ivec2(second_offset, first_offset), size).rgb;
    result = (first + second) * 0.5;
#elif AC_EFFECT_ID == 194
    int distance_value = max(1, int(mix(2.0, 72.0, scale_value)));
    int offset = int(sin(phase + float(pixel.x + pixel.y) * 0.018) *
                     float(distance_value) * strength);
    result = vec3(fetch_clamped(pixel + ivec2(0, offset), size).r,
                  fetch_clamped(pixel - ivec2(offset / 2, offset), size).g,
                  fetch_clamped(pixel + ivec2(offset, -offset), size).b);
#elif AC_EFFECT_ID == 195
    int block_size = max(4, int(mix(8.0, 64.0, scale_value)));
    int diagonal = (pixel.x + pixel.y) / block_size;
    int offset = int(sin(phase + float(diagonal)) * float(block_size) * strength);
    result = fetch_clamped((pixel / block_size) * block_size + ivec2(offset), size).rgb;
#elif AC_EFFECT_ID == 196
    int block_size = max(16, int(mix(24.0, 160.0, scale_value)));
    int diagonal = (pixel.x + pixel.y) / block_size;
    int offset = int(cos(phase * 0.7 + float(diagonal)) * float(block_size) * strength);
    result = fetch_clamped((pixel / block_size) * block_size + ivec2(offset), size).rgb;
#elif AC_EFFECT_ID == 197
    float distance_from_center = abs(uv.x - 0.5) * 2.0;
    float expansion = 1.0 - 0.45 * strength *
                                (0.5 + 0.5 * sin(phase + distance_from_center * 6.0));
    vec2 sample_uv = vec2((uv.x - 0.5) * expansion + 0.5, uv.y);
    result = sample_clamped(sample_uv).rgb;
#elif AC_EFFECT_ID == 198
    int distance_value = max(1, int(mix(2.0, 72.0, scale_value)));
    int red_offset = int(sin(phase + float(pixel.y) * 0.025) *
                         float(distance_value) * strength);
    int green_offset = int(cos(phase * 0.8 + float(pixel.y) * 0.02) *
                           float(distance_value) * strength);
    result = vec3(fetch_clamped(pixel + ivec2(red_offset, 0), size).r,
                  fetch_clamped(pixel + ivec2(green_offset, 0), size).g,
                  fetch_clamped(pixel - ivec2(red_offset, 0), size).b);
#elif AC_EFFECT_ID == 199
    int band_size = max(2, int(mix(3.0, 28.0, scale_value)));
    int band = pixel.y / band_size;
    float random_value = fract(sin(float(band) * 57.583 + floor(phase * 6.0)) *
                                   43758.5453);
    int offset = int((random_value - 0.5) * mix(8.0, 160.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 200
    int distance_value = max(1, int(mix(2.0, 54.0, scale_value)));
    float scratch = fract(sin(float(pixel.y / 3) * 71.91 + floor(phase * 7.0)) *
                             43758.5453);
    int offset = int((scratch - 0.5) * float(distance_value));
    result = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                  fetch_clamped(pixel - ivec2(offset / 2, 0), size).g,
                  fetch_clamped(pixel + ivec2(offset / 3, 0), size).b);
#elif AC_EFFECT_ID == 201
    float pulse = 0.5 + 0.5 * sin(phase);
    int block_size = max(2, int(mix(3.0, 84.0, scale_value) *
                                mix(0.35, 1.0, pulse)));
    vec2 expanded = (uv - 0.5) * mix(1.0, 0.7, pulse * strength) + 0.5;
    ivec2 sample_pixel = ivec2(expanded * vec2(size));
    result = fetch_clamped((sample_pixel / block_size) * block_size, size).rgb;
#elif AC_EFFECT_ID == 202
    ivec2 origin = (pixel / 8) * 8;
    int diagonal = ((origin.x + origin.y) / 8) & 1;
    result = fetch_clamped(origin + (diagonal == 0 ? ivec2(0, 7) : ivec2(7, 0)), size).rgb;
#elif AC_EFFECT_ID == 203
    int block_size = max(4, int(mix(8.0, 72.0, scale_value)));
    ivec2 cell = pixel / block_size;
    float random_value = fract(sin(dot(vec2(cell), vec2(19.19, 83.71)) +
                                   floor(phase * 3.0)) *
                                  43758.5453);
    ivec2 corner = ivec2(random_value > 0.5 ? block_size - 1 : 0,
                         fract(random_value * 13.0) > 0.5 ? block_size - 1 : 0);
    result = fetch_clamped(cell * block_size + corner, size).rgb;
#elif AC_EFFECT_ID == 204
    int block_size = max(4, int(mix(8.0, 68.0, scale_value)));
    ivec2 cell = pixel / block_size;
    int direction = ((cell.x + cell.y) & 1) == 0 ? 1 : -1;
    int offset = int(sin(phase + float(cell.x - cell.y)) *
                     float(block_size) * strength);
    result = fetch_clamped(pixel + ivec2(offset, direction * offset), size).rgb;
#elif AC_EFFECT_ID == 205
    int block_size = max(3, int(mix(6.0, 56.0, scale_value)));
    ivec2 cell = pixel / block_size;
    int direction = ((cell.x + cell.y) & 1) == 0 ? 1 : -1;
    int offset = int(float(block_size) * strength * sin(phase + float(cell.x + cell.y)));
    result = vec3(fetch_clamped(pixel + ivec2(direction * offset, 0), size).r,
                  fetch_clamped(pixel + ivec2(0, offset), size).g,
                  fetch_clamped(pixel - ivec2(direction * offset, offset), size).b);
#elif AC_EFFECT_ID == 206
    int band_size = max(2, int(mix(3.0, 24.0, scale_value)));
    float progress = float(pixel.y) / float(max(size.y - 1, 1));
    int offset = int(progress * mix(4.0, 120.0, scale_value) * strength);
    int direction = ((pixel.y / band_size) & 1) == 0 ? 1 : -1;
    result = vec3(fetch_clamped(pixel + ivec2(direction * offset, 0), size).r,
                  fetch_clamped(pixel - ivec2(direction * offset / 2, 0), size).g,
                  fetch_clamped(pixel + ivec2(direction * offset / 3, 0), size).b);
#elif AC_EFFECT_ID == 207
    int band_size = max(2, int(mix(3.0, 24.0, scale_value)));
    float progress = float(pixel.x) / float(max(size.x - 1, 1));
    int offset = int(progress * mix(4.0, 120.0, scale_value) * strength);
    int direction = ((pixel.x / band_size) & 1) == 0 ? 1 : -1;
    result = vec3(fetch_clamped(pixel + ivec2(0, direction * offset), size).r,
                  fetch_clamped(pixel - ivec2(0, direction * offset / 2), size).g,
                  fetch_clamped(pixel + ivec2(0, direction * offset / 3), size).b);
#elif AC_EFFECT_ID == 208
    int band_size = max(2, int(mix(3.0, 28.0, scale_value)));
    float progress = float(pixel.y) / float(max(size.y - 1, 1));
    int direction = ((pixel.y / band_size) & 1) == 0 ? 1 : -1;
    int offset = int(direction * progress * mix(6.0, 150.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 209
    int band_size = max(2, int(mix(3.0, 28.0, scale_value)));
    float progress = float(pixel.x) / float(max(size.x - 1, 1));
    int direction = ((pixel.x / band_size) & 1) == 0 ? 1 : -1;
    int offset = int(direction * progress * mix(6.0, 150.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 210
    int channel = int(floor(phase * 3.0)) % 3;
    float alpha_value = mix(0.1, 0.5, 0.5 + 0.5 * sin(phase));
    result[channel] = source[channel] * 0.5 * alpha_value;
#elif AC_EFFECT_ID == 211
    int block_size = max(3, int(mix(6.0, 64.0, scale_value)));
    ivec2 origin = (pixel / block_size) * block_size;
    int vertical = int((0.5 + 0.5 * sin(phase)) * float(block_size));
    result = vec3(fetch_clamped(origin + ivec2(0, vertical), size).r,
                  fetch_clamped(origin + ivec2(block_size / 2, vertical / 2), size).g,
                  fetch_clamped(origin + ivec2(block_size - 1, 0), size).b);
#elif AC_EFFECT_ID == 212
    int block_size = max(3, int(mix(6.0, 58.0, scale_value)));
    ivec2 origin = (pixel / block_size) * block_size;
    int offset = int(sin(phase + float(origin.x + origin.y) / float(block_size)) *
                     float(block_size) * strength);
    result = vec3(fetch_clamped(origin + ivec2(offset), size).r,
                  fetch_clamped(origin - ivec2(offset / 2), size).g,
                  fetch_clamped(origin + ivec2(-offset, offset), size).b);
#elif AC_EFFECT_ID == 213
    int block_size = max(3, int(mix(5.0, 72.0, scale_value)));
    ivec2 origin = (pixel / block_size) * block_size;
    int inset = int((0.5 + 0.5 * sin(phase)) * float(block_size - 1));
    result = vec3(fetch_clamped(origin + ivec2(inset, 0), size).r,
                  fetch_clamped(origin + ivec2(0, inset), size).g,
                  fetch_clamped(origin + ivec2(inset), size).b);
#elif AC_EFFECT_ID == 214
    int width_value = max(1, int(mix(2.0, 36.0, scale_value)));
    int band = pixel.x / width_value;
    int offset = int(sin(phase + float(band) * 0.7) *
                     mix(2.0, 70.0, scale_value) * strength);
    result = vec3(fetch_clamped(pixel + ivec2(0, offset), size).r,
                  source.g,
                  fetch_clamped(pixel - ivec2(0, offset), size).b);
#elif AC_EFFECT_ID == 215
    int block_size = max(3, int(mix(6.0, 60.0, scale_value)));
    ivec2 cell = pixel / block_size;
    int direction = ((cell.x + cell.y) & 1) == 0 ? 1 : -1;
    int offset = int(direction * sin(phase + float(cell.x)) *
                     float(block_size) * strength);
    vec3 shifted = fetch_clamped(pixel + ivec2(offset), size).rgb;
    vec3 gradient = 0.5 + 0.5 * cos(phase + vec3(0.0, 2.094, 4.188) +
                                     (uv.x + uv.y) * 6.28318);
    result = shifted * gradient;
#elif AC_EFFECT_ID == 216
    float blend_value = 0.5 + 0.5 * sin(phase);
    vec3 opposite = sample_clamped(vec2(1.0) - uv).rgb;
    result = mix(source.rgb, opposite, blend_value * strength);
#elif AC_EFFECT_ID == 217
    float random_value = fract(sin(floor(phase * 2.0) * 81.731) * 43758.5453);
    vec2 reverse_uv = random_value < 0.25 ? vec2(1.0 - uv.x, uv.y) :
                      random_value < 0.5 ? vec2(uv.x, 1.0 - uv.y) :
                      random_value < 0.75 ? vec2(1.0) - uv : uv;
    result = sample_clamped(reverse_uv).rgb;
#elif AC_EFFECT_ID == 218
    int block_size = max(4, int(mix(8.0, 92.0, scale_value)));
    ivec2 cell = pixel / block_size;
    float random_value = fract(sin(dot(vec2(cell), vec2(18.13, 73.17)) +
                                   floor(phase * 5.0)) *
                                  43758.5453);
    ivec2 offset = ivec2(int((random_value - 0.5) * float(block_size) * 3.0),
                         int((fract(random_value * 11.0) - 0.5) * float(block_size)));
    vec3 shifted = fetch_clamped(pixel + offset, size).rgb;
    result = random_value > 0.45 ? shifted.brg : source.rgb;
#elif AC_EFFECT_ID == 219
    int band_size = max(2, int(mix(4.0, 40.0, scale_value)));
    int band = pixel.y / band_size;
    int direction = (band & 1) == 0 ? 1 : -1;
    int offset = int(direction * sin(phase + float(band)) *
                     mix(4.0, 110.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 220
    int band_size = max(2, int(mix(4.0, 40.0, scale_value)));
    int band = pixel.y / band_size;
    float delayed_phase = phase - float(band) * 0.18;
    int offset = int(sin(delayed_phase) * mix(4.0, 110.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 221
    int band_size = max(2, int(mix(4.0, 44.0, scale_value)));
    int band = pixel.y / band_size;
    int offset = (band & 1) == 0 ?
                     int(sin(phase + float(band)) * mix(5.0, 120.0, scale_value) * strength) :
                     0;
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 222
    vec3 left_color = fetch_clamped(pixel - ivec2(1, 0), size).rgb;
    vec3 right_color = fetch_clamped(pixel + ivec2(1, 0), size).rgb;
    vec3 upper_color = fetch_clamped(pixel - ivec2(0, 1), size).rgb;
    vec3 lower_color = fetch_clamped(pixel + ivec2(0, 1), size).rgb;
    float edge = length((right_color - left_color) + (lower_color - upper_color));
    float paper = 1.0 - smoothstep(mix(0.05, 0.45, scale_value),
                                   mix(0.12, 0.75, scale_value), edge);
    result = mix(source.rgb, vec3(paper), strength);
#elif AC_EFFECT_ID == 223
    int band_size = 32;
    int band = pixel.y / band_size;
    int offset = (band & 1) == 0 ?
                     int(sin(phase + float(band)) * mix(8.0, 140.0, scale_value) * strength) :
                     0;
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 224
    int band_size = max(1, int(mix(2.0, 18.0, scale_value)));
    int band = pixel.y / band_size;
    float random_value = fract(sin(float(band) * 61.713 + floor(phase * 7.0)) *
                                   43758.5453);
    int offset = int((random_value - 0.5) * mix(6.0, 96.0, scale_value) * strength);
    result = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                  fetch_clamped(pixel - ivec2(offset / 2, 0), size).g,
                  fetch_clamped(pixel + ivec2(offset / 3, 0), size).b);
#elif AC_EFFECT_ID == 225
    int band_size = max(1, int(mix(2.0, 18.0, scale_value)));
    int band = pixel.x / band_size;
    float random_value = fract(sin(float(band) * 61.713 + floor(phase * 7.0)) *
                                   43758.5453);
    int offset = int((random_value - 0.5) * mix(6.0, 96.0, scale_value) * strength);
    result = vec3(fetch_clamped(pixel + ivec2(0, offset), size).r,
                  fetch_clamped(pixel - ivec2(0, offset / 2), size).g,
                  fetch_clamped(pixel + ivec2(0, offset / 3), size).b);
#elif AC_EFFECT_ID == 226
    vec3 previous = fetch_clamped(pixel - ivec2(1, 0), size).rgb;
    result = from_u8(to_u8(source.rgb) ^ to_u8(previous));
#elif AC_EFFECT_ID == 227
    vec3 row_average = vec3(0.0);
    for (int sample_index = 0; sample_index < 16; ++sample_index) {
        int sample_x = int((float(sample_index) + 0.5) * float(size.x) / 16.0);
        row_average += fetch_clamped(ivec2(sample_x, pixel.y), size).rgb;
    }
    row_average /= 16.0;
    result = mix(source.rgb, from_u8(to_u8(source.rgb) ^ to_u8(row_average)), 0.5);
#elif AC_EFFECT_ID == 228
    int channel = int(floor(phase * 3.0)) % 3;
    float alpha_value = mix(0.1, 1.0, 0.5 + 0.5 * sin(phase));
    uvec3 value = to_u8(source.rgb);
    value[channel] ^= uint(float(value[channel]) * alpha_value * strength);
    result = from_u8(value);
#elif AC_EFFECT_ID == 229
    float zoom = 1.0 + sin(phase) * mix(0.04, 0.48, scale_value) * strength;
    result = sample_clamped((uv - 0.5) / zoom + 0.5).rgb;
#elif AC_EFFECT_ID == 230
    float zoom = 1.0 + sin(phase * 0.45) * mix(0.03, 0.42, scale_value) * strength;
    result = sample_clamped((uv - 0.5) / zoom + 0.5).rgb;
#elif AC_EFFECT_ID == 231
    float zoom = 1.0 + sin(phase * 1.8) * mix(0.03, 0.42, scale_value) * strength;
    result = sample_clamped((uv - 0.5) / zoom + 0.5).rgb;
#elif AC_EFFECT_ID == 232
    int block_size = max(2, int(mix(3.0, 22.0, scale_value)));
    ivec2 cell = pixel / block_size;
    float random_value = fract(sin(dot(vec2(cell), vec2(33.31, 91.17)) +
                                   floor(phase * 8.0)) *
                                  43758.5453);
    ivec2 offset = ivec2((random_value - 0.5) * mix(4.0, 130.0, scale_value) * strength,
                         (fract(random_value * 17.0) - 0.5) *
                             mix(4.0, 130.0, scale_value) * strength);
    result = fetch_clamped(pixel + offset, size).rgb;
#elif AC_EFFECT_ID == 233
    float progress = float(pixel.y) / float(max(size.y - 1, 1));
    int offset = int(progress * mix(4.0, 180.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 234
    float progress = 1.0 - float(pixel.y) / float(max(size.y - 1, 1));
    int offset = -int(progress * mix(4.0, 180.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 235
    int offset = int(sin(phase + uv.y * mix(8.0, 42.0, scale_value)) *
                     mix(4.0, 150.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 236
    int band_size = max(1, int(mix(2.0, 20.0, scale_value)));
    int band = pixel.y / band_size;
    float random_value = fract(sin(float(band) * 19.731 + floor(phase * 5.0)) *
                                   43758.5453);
    int offset = int((random_value - 0.5) * mix(8.0, 210.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 237
    float progress = float(pixel.x) / float(max(size.x - 1, 1));
    int offset = int(progress * mix(4.0, 180.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 238
    int band_size = max(1, int(mix(2.0, 20.0, scale_value)));
    int band = pixel.x / band_size;
    float random_value = fract(sin(float(band) * 19.731 + floor(phase * 5.0)) *
                                   43758.5453);
    int offset = int((random_value - 0.5) * mix(8.0, 210.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 239
    int offset = int(sin(phase + uv.x * mix(8.0, 42.0, scale_value)) *
                     mix(4.0, 150.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 240
    int band_size = max(2, int(mix(4.0, 42.0, scale_value)));
    int band = pixel.y / band_size;
    int offset = int(sin(phase * 0.7 + float(band) * 0.43) *
                     mix(20.0, 260.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 241
    int band_size = max(2, int(mix(3.0, 26.0, scale_value)));
    int band = pixel.y / band_size;
    float random_value = fract(sin(float(band) * 42.17 + floor(phase * 4.0)) *
                                   43758.5453);
    int offset = int(random_value * mix(10.0, 230.0, scale_value) * strength);
    result = fetch_clamped(pixel - ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 242
    int band_size = max(2, int(mix(3.0, 26.0, scale_value)));
    int band = pixel.x / band_size;
    float random_value = fract(sin(float(band) * 42.17 + floor(phase * 4.0)) *
                                   43758.5453);
    int offset = int(random_value * mix(10.0, 230.0, scale_value) * strength);
    result = fetch_clamped(pixel - ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 243
    int band_size = max(2, int(mix(3.0, 26.0, scale_value)));
    int band = pixel.x / band_size;
    float random_value = fract(sin(float(band) * 42.17 + floor(phase * 4.0)) *
                                   43758.5453);
    int offset = int(random_value * mix(10.0, 230.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 244
    int band_size = max(2, int(mix(3.0, 26.0, scale_value)));
    int band = pixel.y / band_size;
    float random_value = fract(sin(float(band) * 42.17 + floor(phase * 4.0)) *
                                   43758.5453);
    int offset = int(random_value * mix(10.0, 230.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 245
    vec2 centered = uv - 0.5;
    vec2 wave = vec2(sin(uv.y * 23.0 + phase), cos(uv.x * 19.0 - phase)) *
                mix(0.005, 0.12, scale_value) * strength;
    centered *= 1.0 + 0.25 * sin(phase + length(centered) * 12.0) * strength;
    result = sample_clamped(centered + wave + 0.5).rgb;
#elif AC_EFFECT_ID == 246
    float fade = 0.5 + 0.5 * sin(phase);
    result = source.rgb * mix(1.0, fade, strength);
#elif AC_EFFECT_ID == 247
    float distance_value = mix(0.001, 0.06, scale_value) * strength;
    result = vec3(sample_clamped(uv + vec2(distance_value, 0.0)).r,
                  source.g,
                  sample_clamped(uv - vec2(distance_value, 0.0)).b);
#elif AC_EFFECT_ID == 248
    int band_size = max(2, int(mix(3.0, 30.0, scale_value)));
    int band = pixel.x / band_size;
    int offset = int((0.5 + 0.5 * sin(phase + float(band))) *
                     mix(5.0, 130.0, scale_value) * strength);
    result = fetch_clamped(pixel - ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 249
    float random_value = fract(sin(dot(vec2(pixel), vec2(12.9898, 78.233)) +
                                   floor(phase * 15.0)) *
                                  43758.5453);
    float snow = step(mix(0.9, 0.45, scale_value), random_value);
    result = mix(source.rgb, vec3(random_value), snow * strength);
#elif AC_EFFECT_ID == 250
    float first_noise = fract(sin(dot(vec2(pixel), vec2(12.9898, 78.233)) +
                                  floor(phase * 18.0)) *
                                 43758.5453);
    float second_noise = fract(sin(dot(vec2(pixel.yx), vec2(39.346, 11.135)) -
                                   floor(phase * 23.0)) *
                                  24634.6345);
    vec3 snow_color = vec3(first_noise, second_noise,
                           fract(first_noise * 7.0 + second_noise * 3.0));
    result = mix(source.rgb, snow_color,
                 step(mix(0.82, 0.25, scale_value), max(first_noise, second_noise)) * strength);
#elif AC_EFFECT_ID == 251
    int band_size = max(1, int(mix(2.0, 18.0, scale_value)));
    int band = pixel.y / band_size;
    float random_value = fract(sin(float(band) * 65.713 + floor(phase * 9.0)) *
                                   43758.5453);
    int offset = int((random_value - 0.5) * mix(12.0, 260.0, scale_value) * strength);
    vec3 shifted = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
    result = random_value > 0.38 ? shifted : source.rgb;
#elif AC_EFFECT_ID == 252
    int slit = pixel.y / 64;
    int local_y = pixel.y % 64;
    int sample_y = slit * 64 + (63 - local_y);
    result = fetch_clamped(ivec2(pixel.x, sample_y), size).rgb;
#elif AC_EFFECT_ID == 253
    int slit_size = max(4, int(mix(16.0, 128.0, 0.5 + 0.5 * sin(phase))));
    int slit = pixel.y / slit_size;
    int local_y = pixel.y % slit_size;
    result = fetch_clamped(ivec2(pixel.x, slit * slit_size + slit_size - 1 - local_y), size).rgb;
#elif AC_EFFECT_ID == 254
    int slit_size = max(3, int(mix(6.0, 64.0, scale_value)));
    int slit = pixel.y / slit_size;
    float stretch = 1.0 + sin(phase + float(slit) * 0.47) * 0.75 * strength;
    int local_y = int(float(pixel.y % slit_size) / max(stretch, 0.25));
    result = fetch_clamped(ivec2(pixel.x, slit * slit_size + local_y), size).rgb;
#elif AC_EFFECT_ID == 255
    int band_size = max(2, int(mix(3.0, 26.0, scale_value)));
    int band = pixel.y / band_size;
    int direction = (band & 1) == 0 ? 1 : -1;
    int offset = int(direction * (0.5 + 0.5 * sin(phase + float(band) * 0.2)) *
                     mix(8.0, 180.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 256
    int band_size = max(2, int(mix(4.0, 52.0, 0.5 + 0.5 * sin(phase))));
    int band = pixel.y / band_size;
    int direction = (band & 1) == 0 ? 1 : -1;
    float scale = mix(0.65, 1.35, 0.5 + 0.5 * cos(phase + float(band)));
    int sample_x = int((float(pixel.x) - float(size.x) * 0.5) / scale +
                       float(size.x) * 0.5 + direction * float(band_size) * strength);
    result = fetch_clamped(ivec2(sample_x, pixel.y), size).rgb;
#elif AC_EFFECT_ID == 257
    int distance_value = max(2, int(mix(4.0, 96.0, scale_value)));
    int line = pixel.y / max(2, distance_value / 4);
    int offset = int(sin(phase + float(line) * 0.33) * float(distance_value) * strength);
    result = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                  fetch_clamped(pixel - ivec2(offset / 2, 0), size).g,
                  fetch_clamped(pixel - ivec2(offset, 0), size).b);
#elif AC_EFFECT_ID == 258
    int distance_value = max(1, int(mix(3.0, 76.0, scale_value)));
    vec3 first = fetch_clamped(pixel + ivec2(distance_value, 0), size).rgb;
    vec3 second = fetch_clamped(pixel - ivec2(0, distance_value), size).rgb;
    result = vec3((source.r + first.r) * 0.5,
                  (source.g + second.g) * 0.5,
                  (first.b + second.b) * 0.5);
#elif AC_EFFECT_ID == 259
    int distance_value = max(1, int(mix(3.0, 120.0, scale_value) *
                                    (0.25 + 0.75 * abs(sin(phase)))));
    result = vec3(fetch_clamped(pixel + ivec2(distance_value, 0), size).r,
                  fetch_clamped(pixel - ivec2(distance_value / 2, 0), size).g,
                  fetch_clamped(pixel + ivec2(0, distance_value), size).b);
#elif AC_EFFECT_ID == 260
    int distance_value = max(1, int(mix(3.0, 100.0, scale_value)));
    vec3 horizontal = fetch_clamped(pixel + ivec2(distance_value, 0), size).rgb;
    vec3 vertical = fetch_clamped(pixel + ivec2(0, distance_value), size).rgb;
    vec3 diagonal = fetch_clamped(pixel - ivec2(distance_value), size).rgb;
    result = vec3(horizontal.r, vertical.g, diagonal.b);
#elif AC_EFFECT_ID == 261
    int distance_value = max(4, int(mix(12.0, 240.0, scale_value)));
    int offset = int(sin(phase * 0.6) * float(distance_value) * strength);
    result = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                  fetch_clamped(pixel - ivec2(offset, 0), size).g,
                  fetch_clamped(pixel + ivec2(offset / 2, offset / 2), size).b);
#elif AC_EFFECT_ID == 262
    vec3 fade = 0.5 + 0.5 * sin(phase + vec3(0.0, 2.094, 4.188));
    result = mix(source.rgb, source.rgb * fade, strength);
#elif AC_EFFECT_ID == 263
    int distance_value = max(2, int(mix(4.0, 110.0, scale_value)));
    int offset = int(sin(phase * 2.5) * float(distance_value));
    vec3 trail = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                      fetch_clamped(pixel - ivec2(offset, 0), size).g,
                      fetch_clamped(pixel + ivec2(0, offset), size).b);
    result = sin(phase * 4.0) > 0.0 ? trail : vec3(1.0) - trail;
#elif AC_EFFECT_ID == 264
    vec3 frequency = mix(vec3(0.4, 0.7, 1.0), vec3(1.3, 2.1, 3.2), scale_value);
    vec3 fade = 0.5 + 0.5 * sin(phase * frequency + vec3(0.0, 1.7, 3.4));
    result = mix(source.rgb, source.rgb * fade, strength);
#elif AC_EFFECT_ID == 265
    int block_size = max(4, int(mix(8.0, 84.0, scale_value)));
    ivec2 cell = pixel / block_size;
    float random_value = fract(sin(dot(vec2(cell), vec2(27.17, 93.31)) +
                                   floor(phase * 6.0)) *
                                  43758.5453);
    ivec2 offset = ivec2(int((random_value - 0.5) * float(block_size) * 4.0),
                         int((fract(random_value * 19.0) - 0.5) * float(block_size) * 2.0));
    result = random_value > 0.52 ? fetch_clamped(pixel + offset, size).bgr : source.rgb;
#elif AC_EFFECT_ID == 266
    int column_size = max(2, int(mix(3.0, 28.0, scale_value)));
    int column = pixel.x / column_size;
    int offset = int(sin(phase + float(column) * 0.36) *
                     mix(5.0, 150.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 267
    int distance_value = max(1, int(mix(2.0, 36.0, scale_value)));
    vec3 nearby = fetch_clamped(pixel - ivec2(distance_value, distance_value / 2), size).rgb;
    result = mix(source.rgb, nearby, 0.5 * strength);
#elif AC_EFFECT_ID == 268
    vec2 centered = uv - 0.5;
    float inward = mix(1.0, 0.55, (0.5 + 0.5 * sin(phase)) * strength);
    vec2 sample_uv = vec2(sign(centered.x), sign(centered.y)) *
                         pow(abs(centered) * 2.0, vec2(inward)) * 0.5 +
                     0.5;
    result = sample_clamped(sample_uv).rgb;
#elif AC_EFFECT_ID == 269
    int block_size = max(4, int(mix(8.0, 72.0, scale_value)));
    ivec2 cell = pixel / block_size;
    ivec2 center_cell = ivec2(size / block_size) / 2;
    ivec2 direction = ivec2(sign(vec2(center_cell - cell)));
    int offset = int((0.5 + 0.5 * sin(phase + float(cell.x + cell.y))) *
                     float(block_size) * strength);
    result = fetch_clamped(pixel + direction * offset, size).rgb;
#elif AC_EFFECT_ID == 270
    int block_size = max(4, int(mix(8.0, 88.0, 0.5 + 0.5 * sin(phase))));
    ivec2 cell = pixel / block_size;
    ivec2 center_cell = ivec2(size / block_size) / 2;
    ivec2 direction = ivec2(sign(vec2(center_cell - cell)));
    result = fetch_clamped(cell * block_size + direction *
                           int(float(block_size) * strength), size).rgb;
#elif AC_EFFECT_ID == 271
    vec2 pulse = 0.5 + 0.5 * vec2(sin(phase), cos(phase * 0.77));
    ivec2 block_size = max(ivec2(3), ivec2(mix(vec2(6.0), vec2(82.0), pulse * scale_value)));
    ivec2 cell = pixel / block_size;
    ivec2 center_cell = (size / block_size) / 2;
    ivec2 direction = ivec2(sign(vec2(center_cell - cell)));
    result = fetch_clamped(cell * block_size + direction *
                           ivec2(vec2(block_size) * strength), size).rgb;
#elif AC_EFFECT_ID == 272
    int block_size = max(2, int(mix(3.0, 18.0, scale_value)));
    ivec2 cell = pixel / block_size;
    float random_value = fract(sin(dot(vec2(cell), vec2(17.17, 61.91)) +
                                   floor(phase * 12.0)) *
                                  43758.5453);
    int offset = int((random_value - 0.5) * mix(20.0, 220.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, int(offset * 0.25)), size).rgb;
#elif AC_EFFECT_ID == 273
    int block_size = max(2, int(mix(3.0, 38.0, scale_value)));
    ivec2 cell = pixel / block_size;
    int diagonal = cell.x + cell.y;
    ivec2 origin = cell * block_size + ivec2(diagonal % block_size);
    result = fetch_clamped(origin, size).rgb;
#elif AC_EFFECT_ID == 274
    int block_size = max(2, int(mix(4.0, 64.0, 0.5 + 0.5 * sin(phase))));
    ivec2 cell = pixel / block_size;
    int diagonal = cell.x + cell.y;
    result = fetch_clamped(cell * block_size + ivec2(diagonal % block_size), size).rgb;
#elif AC_EFFECT_ID == 275
    int block_size = max(3, int(mix(5.0, 48.0, scale_value)));
    ivec2 cell = pixel / block_size;
    int offset = (cell.x + cell.y) % block_size;
    result = vec3(fetch_clamped(cell * block_size + ivec2(offset), size).r,
                  fetch_clamped(cell * block_size - ivec2(offset / 2), size).g,
                  fetch_clamped(cell * block_size + ivec2(-offset, offset), size).b);
#elif AC_EFFECT_ID == 276
    int distance_value = max(2, int(mix(5.0, 130.0, scale_value)));
    int offset = int(sin(phase) * float(distance_value) * strength);
    vec3 first = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                      fetch_clamped(pixel - ivec2(offset, 0), size).g,
                      fetch_clamped(pixel + ivec2(0, offset), size).b);
    vec3 second = fetch_clamped(pixel - ivec2(offset / 2), size).bgr;
    result = (first + second) * 0.5;
#elif AC_EFFECT_ID == 277
    int offset = int((0.5 + 0.5 * sin(phase)) *
                     mix(8.0, 220.0, scale_value) * strength);
    result = fetch_clamped(pixel - ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 278
    int offset = int((0.5 + 0.5 * sin(phase)) *
                     mix(8.0, 220.0, scale_value) * strength);
    result = fetch_clamped(pixel - ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 279
    int offset = int((0.5 + 0.5 * sin(phase)) *
                     mix(8.0, 190.0, scale_value) * strength);
    result = fetch_clamped(pixel - ivec2(offset), size).rgb;
#elif AC_EFFECT_ID == 280
    int offset = int(sin(phase) * mix(8.0, 180.0, scale_value) * strength);
    vec2 flipped_uv = vec2(1.0 - uv.x, uv.y);
    ivec2 sample_pixel = ivec2(flipped_uv * vec2(size)) + ivec2(offset, 0);
    result = fetch_clamped(sample_pixel, size).rgb;
#elif AC_EFFECT_ID == 281
    float random_value = fract(sin(floor(phase * 3.0) * 93.713) * 43758.5453);
    int offset = int((random_value - 0.5) * mix(10.0, 180.0, scale_value));
    vec2 mirror_uv = random_value < 0.5 ? vec2(1.0 - uv.x, uv.y) :
                                           vec2(uv.x, 1.0 - uv.y);
    result = fetch_clamped(ivec2(mirror_uv * vec2(size)) + ivec2(offset), size).rgb;
#elif AC_EFFECT_ID == 282
    vec2 offset = vec2(sin(phase * 0.73), cos(phase * 1.17)) *
                  mix(0.005, 0.22, scale_value) * strength;
    result = sample_clamped(uv - offset).rgb;
#elif AC_EFFECT_ID == 283
    int distance_value = max(6, int(mix(18.0, 280.0, scale_value)));
    int offset = int(sin(phase * 0.5) * float(distance_value) * strength);
    result = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                  fetch_clamped(pixel - ivec2(offset, 0), size).g,
                  fetch_clamped(pixel + ivec2(offset / 2, 0), size).b);
#elif AC_EFFECT_ID == 284
    int offset = int((float(pixel.x) / float(max(size.x - 1, 1))) *
                     mix(4.0, 150.0, scale_value) * strength);
    result.r = fetch_clamped(pixel - ivec2(offset, 0), size).r;
#elif AC_EFFECT_ID == 285
    int offset = int((float(pixel.x) / float(max(size.x - 1, 1))) *
                     mix(4.0, 150.0, scale_value) * strength);
    result.g = fetch_clamped(pixel - ivec2(offset, 0), size).g;
#elif AC_EFFECT_ID == 286
    int offset = int((float(pixel.x) / float(max(size.x - 1, 1))) *
                     mix(4.0, 150.0, scale_value) * strength);
    result.b = fetch_clamped(pixel - ivec2(offset, 0), size).b;
#elif AC_EFFECT_ID == 287
    int offset = int((float(pixel.y) / float(max(size.y - 1, 1))) *
                     mix(4.0, 150.0, scale_value) * strength);
    result.r = fetch_clamped(pixel - ivec2(0, offset), size).r;
#elif AC_EFFECT_ID == 288
    int offset = int((float(pixel.y) / float(max(size.y - 1, 1))) *
                     mix(4.0, 150.0, scale_value) * strength);
    result.g = fetch_clamped(pixel - ivec2(0, offset), size).g;
#elif AC_EFFECT_ID == 289
    int offset = int((float(pixel.y) / float(max(size.y - 1, 1))) *
                     mix(4.0, 150.0, scale_value) * strength);
    result.b = fetch_clamped(pixel - ivec2(0, offset), size).b;
#elif AC_EFFECT_ID == 290
    int line_size = max(1, int(mix(2.0, 18.0, scale_value)));
    int column = pixel.x / line_size;
    int offset = int(sin(phase + float(column) * 0.51) *
                     mix(3.0, 110.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(0, offset), size).rgb;
#elif AC_EFFECT_ID == 291
    int line_size = max(1, int(mix(2.0, 18.0, scale_value)));
    int row = pixel.y / line_size;
    int offset = int(sin(phase + float(row) * 0.51) *
                     mix(3.0, 110.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 292
    float maximum_value = max(source.r, max(source.g, source.b));
    float minimum_value = min(source.r, min(source.g, source.b));
    float delta = maximum_value - minimum_value;
    float hue = delta < 0.0001 ? 0.0 :
                maximum_value == source.r ? mod((source.g - source.b) / delta, 6.0) / 6.0 :
                maximum_value == source.g ? ((source.b - source.r) / delta + 2.0) / 6.0 :
                                             ((source.r - source.g) / delta + 4.0) / 6.0;
    float saturation = maximum_value < 0.0001 ? 0.0 : delta / maximum_value;
    vec3 tripped = hsv_to_rgb(vec3(fract(hue + phase * 0.05 * strength),
                                   clamp(saturation * mix(1.0, 2.0, scale_value), 0.0, 1.0),
                                   maximum_value));
    result = mix(source.rgb, tripped, strength);
#elif AC_EFFECT_ID == 293
    int line_size = max(2, int(mix(3.0, 24.0, scale_value)));
    int diagonal = (pixel.x + pixel.y) / line_size;
    float expansion = sin(phase + float(diagonal) * 0.27) *
                      mix(3.0, 120.0, scale_value) * strength;
    ivec2 direction = ivec2(pixel.x < size.x / 2 ? -1 : 1,
                            pixel.y < size.y / 2 ? -1 : 1);
    result = fetch_clamped(pixel + direction * int(expansion), size).rgb;
#elif AC_EFFECT_ID == 294
    float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
    float contrast = mix(0.7, 2.8, scale_value);
    vec3 mapped = clamp((source.rgb - luminance) * contrast +
                        smoothstep(0.0, 1.0, luminance), 0.0, 1.0);
    result = mix(source.rgb, mapped, strength);
#elif AC_EFFECT_ID == 295
    uvec3 value = to_u8(source.rgb);
    uint sum_value = (value.r + value.g + value.b) & 255u;
    uint mask = uint(float(sum_value) * (0.5 + 0.5 * sin(phase)) * strength);
    result = from_u8(value ^ uvec3(mask));
#elif AC_EFFECT_ID == 296
    float left_value = dot(fetch_clamped(pixel - ivec2(1, 0), size).rgb,
                           vec3(0.299, 0.587, 0.114));
    float right_value = dot(fetch_clamped(pixel + ivec2(1, 0), size).rgb,
                            vec3(0.299, 0.587, 0.114));
    float upper_value = dot(fetch_clamped(pixel - ivec2(0, 1), size).rgb,
                            vec3(0.299, 0.587, 0.114));
    float lower_value = dot(fetch_clamped(pixel + ivec2(0, 1), size).rgb,
                            vec3(0.299, 0.587, 0.114));
    float edge = clamp(abs(right_value - left_value) + abs(lower_value - upper_value), 0.0, 1.0);
    result = mix(source.rgb, vec3(edge), strength);
#elif AC_EFFECT_ID == 297
    float top_left = dot(fetch_clamped(pixel + ivec2(-1, -1), size).rgb, vec3(0.299, 0.587, 0.114));
    float top = dot(fetch_clamped(pixel + ivec2(0, -1), size).rgb, vec3(0.299, 0.587, 0.114));
    float top_right = dot(fetch_clamped(pixel + ivec2(1, -1), size).rgb, vec3(0.299, 0.587, 0.114));
    float left_value = dot(fetch_clamped(pixel + ivec2(-1, 0), size).rgb, vec3(0.299, 0.587, 0.114));
    float right_value = dot(fetch_clamped(pixel + ivec2(1, 0), size).rgb, vec3(0.299, 0.587, 0.114));
    float bottom_left = dot(fetch_clamped(pixel + ivec2(-1, 1), size).rgb, vec3(0.299, 0.587, 0.114));
    float bottom = dot(fetch_clamped(pixel + ivec2(0, 1), size).rgb, vec3(0.299, 0.587, 0.114));
    float bottom_right = dot(fetch_clamped(pixel + ivec2(1, 1), size).rgb, vec3(0.299, 0.587, 0.114));
    float gradient_x = -top_left - 2.0 * left_value - bottom_left +
                       top_right + 2.0 * right_value + bottom_right;
    float gradient_y = -top_left - 2.0 * top - top_right +
                       bottom_left + 2.0 * bottom + bottom_right;
    float edge = clamp(length(vec2(gradient_x, gradient_y)), 0.0, 1.0);
    result = mix(source.rgb, vec3(edge), strength);
#elif AC_EFFECT_ID == 298
    float top_left = dot(fetch_clamped(pixel + ivec2(-1, -1), size).rgb, vec3(0.299, 0.587, 0.114));
    float top = dot(fetch_clamped(pixel + ivec2(0, -1), size).rgb, vec3(0.299, 0.587, 0.114));
    float top_right = dot(fetch_clamped(pixel + ivec2(1, -1), size).rgb, vec3(0.299, 0.587, 0.114));
    float left_value = dot(fetch_clamped(pixel + ivec2(-1, 0), size).rgb, vec3(0.299, 0.587, 0.114));
    float right_value = dot(fetch_clamped(pixel + ivec2(1, 0), size).rgb, vec3(0.299, 0.587, 0.114));
    float bottom_left = dot(fetch_clamped(pixel + ivec2(-1, 1), size).rgb, vec3(0.299, 0.587, 0.114));
    float bottom = dot(fetch_clamped(pixel + ivec2(0, 1), size).rgb, vec3(0.299, 0.587, 0.114));
    float bottom_right = dot(fetch_clamped(pixel + ivec2(1, 1), size).rgb, vec3(0.299, 0.587, 0.114));
    float gradient_x = -top_left - 2.0 * left_value - bottom_left +
                       top_right + 2.0 * right_value + bottom_right;
    float gradient_y = -top_left - 2.0 * top - top_right +
                       bottom_left + 2.0 * bottom + bottom_right;
    float edge = length(vec2(gradient_x, gradient_y));
    float threshold_value = mix(0.05, 0.7, scale_value);
    result = mix(source.rgb, vec3(step(threshold_value, edge)), strength);
#elif AC_EFFECT_ID == 299
    int radius = max(1, int(mix(1.0, 5.0, scale_value)));
    vec3 first = fetch_clamped(pixel - ivec2(radius, 0), size).rgb;
    vec3 second = fetch_clamped(pixel + ivec2(radius, 0), size).rgb;
    vec3 third = fetch_clamped(pixel - ivec2(0, radius), size).rgb;
    vec3 fourth = fetch_clamped(pixel + ivec2(0, radius), size).rgb;
    vec3 minimum_color = min(source.rgb, min(first, min(second, min(third, fourth))));
    vec3 maximum_color = max(source.rgb, max(first, max(second, max(third, fourth))));
    result = source.rgb + first + second + third + fourth - minimum_color - maximum_color;
    result /= 3.0;
#elif AC_EFFECT_ID == 300
    float bar_count = mix(4.0, 48.0, scale_value);
    float bar = 0.5 + 0.5 * sin(uv.y * bar_count * 6.28318 + phase * 2.0);
    result = source.rgb * mix(0.15, 1.4, bar * strength + (1.0 - strength));
#elif AC_EFFECT_ID == 301
    uint mask_value = uint(clamp((0.5 + 0.5 * sin(phase * 4.0)) *
                                     mix(16.0, 255.0, scale_value),
                                 0.0, 255.0));
    result = from_u8(to_u8(source.rgb) ^ uvec3(mask_value));
#elif AC_EFFECT_ID == 302
    int band_size = max(2, int(mix(3.0, 40.0, scale_value)));
    vec2 mirror_uv = ((pixel.y / band_size) & 1) == 0
                         ? vec2(1.0 - uv.x, uv.y)
                         : vec2(uv.x, 1.0 - uv.y);
    result = mix(source.rgb, sample_clamped(mirror_uv).rgb, strength);
#elif AC_EFFECT_ID == 303
    int spacing = max(2, int(mix(3.0, 32.0, scale_value)));
    int channel = ((pixel.x / spacing) + (pixel.y / spacing)) % 3;
    vec3 alternate = sample_clamped(vec2(1.0) - uv).rgb;
    result = channel == 0 ? vec3(alternate.r, source.g, source.b) :
             channel == 1 ? vec3(source.r, alternate.g, source.b) :
                            vec3(source.r, source.g, alternate.b);
#elif AC_EFFECT_ID == 304
    int spacing = max(2, int(mix(3.0, 36.0, scale_value)));
    int channel = (pixel.y / spacing) % 3;
    vec3 shifted = fetch_clamped(pixel + ivec2(int(sin(phase) * float(spacing)), 0), size).rgb;
    result = channel == 0 ? vec3(shifted.r, source.g, source.b) :
             channel == 1 ? vec3(source.r, shifted.g, source.b) :
                            vec3(source.r, source.g, shifted.b);
#elif AC_EFFECT_ID == 305
    int spacing = max(2, int(mix(3.0, 36.0, scale_value)));
    int channel = (pixel.x / spacing) % 3;
    vec3 shifted = fetch_clamped(pixel + ivec2(0, int(cos(phase) * float(spacing))), size).rgb;
    result = channel == 0 ? vec3(shifted.r, source.g, source.b) :
             channel == 1 ? vec3(source.r, shifted.g, source.b) :
                            vec3(source.r, source.g, shifted.b);
#elif AC_EFFECT_ID == 306
    vec3 horizontal = sample_clamped(vec2(1.0 - uv.x, uv.y)).rgb;
    vec3 vertical = sample_clamped(vec2(uv.x, 1.0 - uv.y)).rgb;
    vec3 opposite = sample_clamped(vec2(1.0) - uv).rgb;
    float blend_value = 0.5 + 0.5 * sin(phase);
    result = mix(mix(source.rgb, horizontal, blend_value),
                 mix(vertical, opposite, blend_value), strength);
#elif AC_EFFECT_ID == 307
    uint multiplier = uint(1 + int((0.5 + 0.5 * sin(phase)) *
                                   mix(1.0, 15.0, scale_value)));
    uvec3 value = to_u8(source.rgb);
    result = from_u8(value ^ (value * multiplier));
#elif AC_EFFECT_ID == 308
    int offset = max(1, int(mix(1.0, 48.0, scale_value)));
    vec3 separated = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                          fetch_clamped(pixel - ivec2(0, offset), size).g,
                          fetch_clamped(pixel - ivec2(offset, 0), size).b);
    result = mix(source.rgb, separated, strength);
#elif AC_EFFECT_ID == 309
    int offset = max(1, int(mix(1.0, 48.0, scale_value)));
    uvec3 separated = uvec3(to_u8(fetch_clamped(pixel + ivec2(offset, 0), size).rgb).r,
                            to_u8(fetch_clamped(pixel - ivec2(0, offset), size).rgb).g,
                            to_u8(fetch_clamped(pixel - ivec2(offset, 0), size).rgb).b);
    result = from_u8(to_u8(source.rgb) ^ separated);
#elif AC_EFFECT_ID == 310
    int offset = max(1, int((0.5 + 0.5 * sin(phase)) *
                            mix(3.0, 120.0, scale_value)));
    vec3 separated = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                          fetch_clamped(pixel + ivec2(0, offset), size).g,
                          fetch_clamped(pixel - ivec2(offset), size).b);
    result = mix(source.rgb, separated, strength);
#elif AC_EFFECT_ID == 311
    int offset = max(1, int(mix(2.0, 54.0, scale_value)));
    vec3 separated = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                          fetch_clamped(pixel - ivec2(0, offset), size).g,
                          fetch_clamped(pixel - ivec2(offset, 0), size).b);
    result = mix(source.rgb, separated * mix(0.15, 0.65, strength), 0.75);
#elif AC_EFFECT_ID == 312
    float divisor = mix(0.08, 0.8, scale_value);
    vec3 remainder = mod(source.rgb + vec3(phase * 0.03), vec3(divisor));
    result = mix(source.rgb, remainder / divisor, strength) *
             mix(0.35, 0.9, 0.5 + 0.5 * sin(phase));
#elif AC_EFFECT_ID == 313
    int line_size = max(1, int(mix(1.0, 12.0, scale_value)));
    int line = pixel.y / line_size;
    int offset = int(sin(phase * 8.0 + float(line) * 0.47) *
                     mix(2.0, 48.0, scale_value) * strength);
    result = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
#elif AC_EFFECT_ID == 314
    vec3 cycled = source.gbr;
    float difference = 0.5 + 0.5 * sin(phase);
    result = mix(source.rgb, abs(source.rgb - cycled) *
                             mix(1.0, 3.0, scale_value),
                 difference * strength);
#elif AC_EFFECT_ID == 315
    vec3 difference = abs(source.rgb - source.brg) *
                      mix(0.75, 3.5, scale_value);
    result = mix(source.rgb, difference, strength *
                 (0.5 + 0.5 * sin(phase)));
#elif AC_EFFECT_ID == 316
    float high_value = max(source.r, max(source.g, source.b));
    float low_value = min(source.r, min(source.g, source.b));
    float middle_value = source.r + source.g + source.b - high_value - low_value;
    result = vec3(high_value, middle_value, low_value);
#elif AC_EFFECT_ID == 317
    float high_value = max(source.r, max(source.g, source.b));
    float low_value = min(source.r, min(source.g, source.b));
    float middle_value = source.r + source.g + source.b - high_value - low_value;
    result = vec3(low_value, middle_value, high_value);
#elif AC_EFFECT_ID == 318
    float random_value = random_hash(vec2(pixel), floor(phase * 12.0));
    float threshold_value = mix(0.995, 0.82, strength);
    result = random_value > threshold_value ? vec3(1.0) : source.rgb;
#elif AC_EFFECT_ID == 319
    float random_value = random_hash(vec2(pixel), floor(phase * 12.0));
    float threshold_value = mix(0.995, 0.82, strength);
    result = random_value > threshold_value ? source.rgb * 0.08 : source.rgb;
#elif AC_EFFECT_ID == 320
    int bar_size = max(2, int(mix(4.0, 54.0, scale_value)));
    int bar = pixel.y / bar_size;
    vec3 palette = 0.5 + 0.5 * cos(float(bar) + phase +
                                   vec3(0.0, 2.094, 4.188));
    result = mix(source.rgb, source.rgb * palette * 1.8, strength);
#elif AC_EFFECT_ID == 321
    int radius = max(1, int(mix(1.0, 20.0, scale_value)));
    vec3 horizontal = fetch_clamped(pixel + ivec2(radius, 0), size).rgb;
    vec3 vertical = fetch_clamped(pixel + ivec2(0, radius), size).rgb;
    vec3 diagonal = fetch_clamped(pixel - ivec2(radius), size).rgb;
    result = mix(source.rgb, (horizontal + vertical + diagonal) / 3.0, strength);
#elif AC_EFFECT_ID == 322
    uvec3 value = to_u8(source.rgb);
    uvec3 gradient = uvec3(uint(uv.x * 255.0), uint(uv.y * 255.0),
                           uint(fract(uv.x + uv.y + phase * 0.05) * 255.0));
    result = from_u8(value ^ gradient);
#elif AC_EFFECT_ID == 323
    float streak = pow(random_hash(vec2(floor(uv.x * mix(30.0, 180.0, scale_value)), 0.0),
                                   floor(phase * 3.0)), 8.0);
    float fall = fract(uv.y + phase * 0.08 + streak);
    vec3 purple = vec3(0.75, 0.12, 1.0) * streak * smoothstep(1.0, 0.2, fall);
    result = mix(source.rgb, clamp(source.rgb * 0.55 + purple, 0.0, 1.0), strength);
#elif AC_EFFECT_ID == 324
    uvec3 value = to_u8(source.rgb);
    uvec3 pattern = uvec3(uint(pixel.x), uint(pixel.y),
                          uint(pixel.x + pixel.y + int(phase * 20.0))) & uvec3(255u);
    result = from_u8(value ^ pattern);
#elif AC_EFFECT_ID == 325
    int offset = max(1, int(mix(1.0, 42.0, scale_value)));
    uvec3 copied = to_u8(fetch_clamped(pixel + ivec2(offset, offset / 2), size).rgb);
    vec3 xor_color = from_u8(to_u8(source.rgb) ^ copied);
    result = mix(source.rgb, xor_color, strength);
#elif AC_EFFECT_ID == 326
    int radius = max(1, int(mix(1.0, 16.0, scale_value)));
    vec3 average_color = (fetch_clamped(pixel - ivec2(radius, 0), size).rgb +
                          fetch_clamped(pixel + ivec2(radius, 0), size).rgb +
                          fetch_clamped(pixel - ivec2(0, radius), size).rgb +
                          fetch_clamped(pixel + ivec2(0, radius), size).rgb) * 0.25;
    result = from_u8(to_u8(source.rgb) ^ to_u8(average_color));
#elif AC_EFFECT_ID == 327
    int radius = max(1, int(mix(1.0, 20.0, scale_value)));
    vec3 average_color = (source.rgb +
                          fetch_clamped(pixel - ivec2(radius, 0), size).rgb +
                          fetch_clamped(pixel + ivec2(radius, 0), size).rgb +
                          fetch_clamped(pixel - ivec2(0, radius), size).rgb +
                          fetch_clamped(pixel + ivec2(0, radius), size).rgb) * 0.2;
    result = mix(source.rgb, average_color, strength);
#elif AC_EFFECT_ID == 328
    int spacing = max(1, int(mix(1.0, 18.0, scale_value)));
    result = ((pixel.y / spacing) & 1) == 0 ? source.rgb : vec3(1.0) - source.rgb;
#elif AC_EFFECT_ID == 329
    int spacing = max(1, int(mix(2.0, 22.0, scale_value)));
    int line = pixel.y / spacing;
    int offset = ((line & 1) == 0 ? 1 : -1) *
                 int(mix(2.0, 70.0, strength));
    vec3 shifted = fetch_clamped(pixel + ivec2(offset, 0), size).rgb;
    result = vec3(shifted.r, source.g, shifted.b);
#elif AC_EFFECT_ID == 330
    int offset = int(sin(phase + float(pixel.y) * 0.03) *
                     mix(2.0, 64.0, scale_value));
    uvec3 shifted = to_u8(fetch_clamped(pixel + ivec2(offset, 0), size).rgb);
    result = from_u8(to_u8(source.rgb) ^ shifted);
#elif AC_EFFECT_ID == 331
    uvec3 value = to_u8(source.rgb);
    uint mask_value = uint(32 + int((0.5 + 0.5 * sin(phase * 3.0)) * 223.0));
    int mode = int(floor(mod(phase, 3.0)));
    result = mode == 0 ? from_u8(value ^ uvec3(mask_value)) :
             mode == 1 ? from_u8(value & uvec3(mask_value)) :
                         from_u8(value | uvec3(mask_value));
#elif AC_EFFECT_ID == 332
    uvec3 value = to_u8(source.rgb);
    uint source_mask = (value.r + value.g + value.b) / 3u;
    result = from_u8(value ^ uvec3(source_mask));
#elif AC_EFFECT_ID == 333
    int offset = int(sin(phase) * mix(2.0, 72.0, scale_value));
    result = vec3(fetch_clamped(pixel + ivec2(offset, 0), size).r,
                  source.g,
                  fetch_clamped(pixel - ivec2(offset, 0), size).b);
#elif AC_EFFECT_ID == 334
    float random_value = random_hash(vec2(pixel / max(1, int(mix(1.0, 12.0, scale_value)))),
                                     floor(phase * 8.0));
    int channel = int(floor(random_value * 3.0));
    result = source.rgb;
    result[channel] = clamp(result[channel] * mix(1.0, 3.0, strength), 0.0, 1.0);
#elif AC_EFFECT_ID == 335
    float division = step(0.5, uv.y);
    vec3 upper = source.rgb * vec3(1.0, 0.55, 1.35);
    vec3 lower = source.rgb * vec3(1.35, 1.0, 0.55);
    result = mix(source.rgb, mix(upper, lower, division), strength);
#elif AC_EFFECT_ID == 336
    float division = step(0.5, uv.x);
    vec3 left_color = source.rgb * vec3(0.55, 1.35, 1.0);
    vec3 right_color = source.rgb * vec3(1.35, 0.55, 1.0);
    result = mix(source.rgb, mix(left_color, right_color, division), strength);
#elif AC_EFFECT_ID == 337
    float gamma_value = mix(0.45, 2.8, 0.5 + 0.5 * sin(phase));
    vec3 adjusted = pow(max(source.rgb, vec3(0.0001)), vec3(gamma_value));
    result = mix(source.rgb, adjusted, strength);
#elif AC_EFFECT_ID == 338
    float range_value = mix(0.25, 3.5, scale_value);
    float gamma_value = mix(1.0 / max(range_value, 0.1), range_value,
                            0.5 + 0.5 * sin(phase));
    vec3 adjusted = pow(max(source.rgb, vec3(0.0001)), vec3(gamma_value));
    result = mix(source.rgb, adjusted, strength);
#elif AC_EFFECT_ID == 339
    vec2 centered = uv - 0.5;
    float radius = length(centered);
    float base_angle = atan(centered.y, centered.x);
    float twist = sin(radius * mix(10.0, 54.0, scale_value) - phase) *
                  strength * 1.8;
    vec2 red_uv = vec2(cos(base_angle + twist), sin(base_angle + twist)) * radius + 0.5;
    vec2 blue_uv = vec2(cos(base_angle - twist), sin(base_angle - twist)) * radius + 0.5;
    result = vec3(sample_clamped(red_uv).r, source.g, sample_clamped(blue_uv).b);
#elif AC_EFFECT_ID == 340
    int mode = int(floor(random_hash(vec2(floor(phase * 2.0)), 7.0) * 4.0));
    vec2 flip_uv = mode == 0 ? uv :
                   mode == 1 ? vec2(1.0 - uv.x, uv.y) :
                   mode == 2 ? vec2(uv.x, 1.0 - uv.y) : vec2(1.0) - uv;
    result = sample_clamped(flip_uv).rgb;
#elif AC_EFFECT_ID == 341
    vec3 negative = vec3(1.0) - source.rgb;
    vec3 paradox = abs(negative - source.gbr) * mix(1.0, 2.5, scale_value);
    result = mix(source.rgb, paradox, strength * (0.5 + 0.5 * sin(phase)));
#elif AC_EFFECT_ID == 342
    float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
    float levels = floor(mix(3.0, 12.0, scale_value));
    float posterized = floor(luminance * levels) / max(levels - 1.0, 1.0);
    vec3 thought_color = 0.5 + 0.5 * cos(posterized * 8.0 + phase +
                                         vec3(0.0, 2.094, 4.188));
    result = mix(source.rgb, thought_color, strength);
#elif AC_EFFECT_ID == 343
    vec3 rainbow = 0.5 + 0.5 * cos(phase +
                                   vec3(uv.x, uv.y, uv.x + uv.y) *
                                       mix(4.0, 24.0, scale_value) +
                                   vec3(0.0, 2.094, 4.188));
    result = mix(source.rgb, source.rgb * rainbow * 1.8, strength);
#elif AC_EFFECT_ID == 344
    vec2 cell = floor(vec2(pixel) / mix(2.0, 32.0, scale_value));
    vec3 random_color = vec3(random_hash(cell, floor(phase * 2.0)),
                             random_hash(cell + vec2(19.0, 7.0), floor(phase * 2.0)),
                             random_hash(cell + vec2(3.0, 29.0), floor(phase * 2.0)));
    result = mix(source.rgb, random_color, strength);
#elif AC_EFFECT_ID == 345
    vec3 curved = sin(source.rgb * mix(1.0, 5.0, scale_value) * 3.14159 +
                      phase * vec3(0.13, 0.19, 0.27));
    result = mix(source.rgb, abs(curved), strength);
#elif AC_EFFECT_ID == 346
    int order_index = int(floor(mod(phase, 6.0)));
    result = order_index == 0 ? source.rgb :
             order_index == 1 ? source.rbg :
             order_index == 2 ? source.grb :
             order_index == 3 ? source.gbr :
             order_index == 4 ? source.brg : source.bgr;
#elif AC_EFFECT_ID == 347
    int square_size = max(2, int(mix(3.0, 48.0, scale_value)));
    ivec2 cell = pixel / square_size;
    uint mask_value = ((cell.x + cell.y) & 1) == 0 ? 85u : 170u;
    result = from_u8(to_u8(source.rgb) ^ uvec3(mask_value));
#elif AC_EFFECT_ID == 348
    int radius = max(1, int(mix(1.0, 28.0, scale_value)));
    vec3 left_color = fetch_clamped(pixel - ivec2(radius, 0), size).rgb;
    vec3 right_color = fetch_clamped(pixel + ivec2(radius, 0), size).rgb;
    result = mix(source.rgb, (left_color + source.rgb + right_color) / 3.0, strength);
#elif AC_EFFECT_ID == 349
    int radius = max(1, int(mix(1.0, 28.0, scale_value)));
    vec3 upper_color = fetch_clamped(pixel - ivec2(0, radius), size).rgb;
    vec3 lower_color = fetch_clamped(pixel + ivec2(0, radius), size).rgb;
    result = mix(source.rgb, (upper_color + source.rgb + lower_color) / 3.0, strength);
#endif

    result = mix(source.rgb, result, clamp(mix_amount, 0.0, 1.0));
    imageStore(output_image, pixel, vec4(clamp(result, 0.0, 1.0), source.a));
}
