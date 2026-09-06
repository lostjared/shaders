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
#endif

    result = mix(source.rgb, result, clamp(mix_amount, 0.0, 1.0));
    imageStore(output_image, pixel, vec4(clamp(result, 0.0, 1.0), source.a));
}
