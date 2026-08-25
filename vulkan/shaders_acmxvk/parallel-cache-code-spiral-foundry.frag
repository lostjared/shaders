#version 450

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
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// Molten metallic spiral grooves cast from spectrum-colored cache layers.
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
layout(set = 0, binding = 3) uniform sampler1D spectrum0;
layout(set = 0, binding = 4) uniform sampler1DArray spectrum_history;


#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif






const float TAU = 6.28318530718;

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.52 + 0.48 * cos(TAU * (phase + vec3(0.08, 0.43, 0.76)));
}

vec4 sample_cache(int index, vec2 uv) {
    uv = mirror_repeat(uv);
    if (index == 0) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (index == 1) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (index == 2) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (index == 3) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (index == 4) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (index == 5) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (index == 6) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

float sample_history(int index, float frequency) {
    if (index == 0) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (index == 1) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (index == 2) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (index == 3) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (index == 4) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (index == 5) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(7)))).r;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.5 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);
    float radius = length(point) + 0.002;
    float angle = atan(point.y, point.x);
    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.82).r;

    float depth = 1.0 / (radius + 0.06) + time_f * (1.2 + bass * 2.5);
    float groove = sin(angle * (10.0 + floor(treble * 5.0)) - depth * 4.2);
    float cross_groove = cos(angle * 19.0 + depth * 6.1 + mid * 4.0);
    // Four complete mirror periods make the atan wrap continuous at the left edge.
    vec2 cast_uv = vec2(angle / TAU * 4.0 + depth * 0.11 + groove * 0.06,
                        depth * 0.33 + log(radius) * 0.65 + cross_groove * 0.08);
    vec3 live = texture(samp, mirror_repeat(cast_uv)).rgb;
    vec3 accum = live;
    float total_weight = 1.0;

    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.03);
        float old_mid = sample_history(i, 0.22);
        float old_air = sample_history(i, 0.82);
        vec2 history_uv = cast_uv * vec2(1.0 - age * old_bass * 0.012,
                                         1.0 + age * old_mid * 0.015);
        history_uv += vec2(age * (0.035 + old_air * 0.04),
                           sin(age + time_f) * old_mid * 0.07);
        vec3 cached = sample_cache(i, history_uv).rgb;
        float heat = sample_history(i, 0.58);
        cached = mix(cached, cached.bgr, 0.2 + heat * 0.35);
        float weight = pow(0.77, age);
        accum += cached * palette(age * 0.075 + old_mid + depth * 0.02) * weight;
        total_weight += weight;
    }

    vec3 result = accum / total_weight;
    float metal = pow(0.5 + 0.5 * groove, 4.0);
    float spark = pow(max(cross_groove, 0.0), 10.0);
    result *= 0.48 + metal * (1.0 + bass) + abs(cross_groove) * 0.2;
    result += palette(depth * 0.03 - time_f * 0.04) * spark * (0.25 + air * 1.4);
    result = (result - 0.5) * (1.25 + amp_smooth * 0.25) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.88, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
