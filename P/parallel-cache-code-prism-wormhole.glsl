#version 330 core
// Chromatic inverse-radius tunnel with spectrum-history prisms.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif

uniform sampler1D spectrum0;
uniform sampler1DArray spectrum_history;
uniform int spectrum_history_head;
uniform int spectrum_history_size;
#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif

uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;

mat2 rotate_2d(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 spectrum_palette(float phase) {
    return 0.54 + 0.46 * cos(TAU * (phase + vec3(0.0, 0.29, 0.61)));
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

    float bass = texture(spectrum0, 0.025).r;
    float mid = texture(spectrum0, 0.20).r;
    float treble = texture(spectrum0, 0.61).r;
    float air = texture(spectrum0, 0.84).r;

    float tunnel = 1.0 / (radius + 0.035 + bass * 0.035);
    float spokes = 4.0 + floor(treble * 7.0);
    float spiral = angle * spokes + tunnel * (1.15 + mid) - time_f * (2.8 + bass * 4.0);
    float ridge = pow(0.5 + 0.5 * sin(spiral), 5.0);
    vec2 tunnel_uv = vec2(angle / TAU * spokes + tunnel * 0.14,
                          tunnel * 0.22 - time_f * (0.25 + bass * 0.2));
    tunnel_uv += vec2(cos(spiral), sin(spiral)) * (0.045 + treble * 0.05);

    float chroma = 0.015 + ridge * 0.065 + treble * 0.025;
    vec3 live;
    live.r = texture(samp, mirror_repeat(tunnel_uv + vec2(chroma, 0.0))).r;
    live.g = texture(samp, mirror_repeat(tunnel_uv)).g;
    live.b = texture(samp, mirror_repeat(tunnel_uv - vec2(chroma, 0.0))).b;

    vec3 accum = live;
    float total_weight = 1.0;
    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.025);
        float old_mid = sample_history(i, 0.20);
        float old_high = sample_history(i, 0.61);
        vec2 old_point = rotate_2d(age * (0.035 + old_high * 0.14)) * point;
        old_point *= pow(max(0.965 - old_bass * 0.06, 0.55), age);
        float old_radius = length(old_point) + 0.002;
        float old_angle = atan(old_point.y, old_point.x);
        float old_tunnel = 1.0 / (old_radius + 0.04);
        vec2 history_uv = vec2(old_angle / TAU * spokes + old_tunnel * 0.14,
                               old_tunnel * 0.22 + age * (0.035 + old_mid * 0.08));
        vec3 cached = sample_cache(i, history_uv).rgb;
        cached = mix(cached, cached.bgr, 0.18 + old_high * 0.38);
        float weight = pow(0.77, age) * (0.8 + old_bass * 0.5);
        accum += cached * spectrum_palette(age * 0.1 + old_mid + tunnel * 0.02) * weight;
        total_weight += weight;
    }

    vec3 result = accum / total_weight;
    result = (result - 0.5) * (1.18 + amp_smooth * 0.35) + 0.5;
    result += spectrum_palette(spiral / TAU + time_f * 0.05) * ridge * (0.35 + air);
    float center_glow = exp(-radius * (7.0 - bass * 3.0));
    result += spectrum_palette(time_f * 0.1 + mid) * center_glow * (0.1 + bass * 0.6);
    result = mix(result, vec3(1.0) - result, smoothstep(0.87, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
