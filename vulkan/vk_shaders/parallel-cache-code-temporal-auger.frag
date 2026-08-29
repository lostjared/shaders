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

// Logarithmic auger carrying historical FFT energy down an eight-frame tunnel.
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
    return 0.53 + 0.47 * cos(TAU * (phase + vec3(0.24, 0.57, 0.9)));
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

    float depth = 1.0 / (radius + 0.045) + time_f * (1.8 + bass * 2.8);
    float blade = sin(angle * (9.0 + floor(treble * 6.0)) - depth * (3.2 + mid * 2.0));
    float teeth = cos(angle * 21.0 + depth * 5.4);
    float twist = angle + depth * (0.68 + bass * 0.25) + blade * 0.15;
    vec2 auger_uv = vec2(twist / TAU * 4.0 + teeth * 0.055,
                         depth * 0.32 + log(radius) * 0.72 + blade * 0.1);
    vec3 live = texture(samp, mirror_repeat(auger_uv)).rgb;
    vec3 accum = live;
    float total_weight = 1.0;

    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.03);
        float old_mid = sample_history(i, 0.22);
        float old_high = sample_history(i, 0.58);
        float old_air = sample_history(i, 0.82);
        float flow = age * (0.34 + old_bass * 1.4);
        float old_twist = twist + age * (0.07 + old_high * 0.26);
        vec2 history_uv = vec2(old_twist / TAU * 4.0 + flow * 0.08,
                               depth * 0.32 + log(radius) * 0.72 + flow);
        history_uv += vec2(sin(flow + time_f), cos(flow - time_f)) * old_mid * 0.075;
        vec3 cached = sample_cache(i, history_uv).rgb;
        cached.r *= 1.0 + old_mid * 0.35;
        cached.g *= 1.0 - old_bass * 0.18;
        cached.b *= 1.0 + old_air * 0.4;
        float weight = pow(0.8, age) * (0.75 + old_bass * 0.55);
        accum += cached * weight;
        total_weight += weight;
    }

    vec3 result = accum / total_weight;
    float blade_light = pow(0.5 + 0.5 * blade, 5.0);
    float tooth_light = pow(max(teeth, 0.0), 10.0);
    result = mix(result, result.bgr, 0.16 + blade_light * 0.3);
    result *= 0.55 + blade_light * (0.9 + mid) + abs(teeth) * 0.2;
    result += palette(depth * 0.025 + time_f * 0.05) * tooth_light * (0.2 + air);
    result = (result - 0.5) * (1.22 + amp_smooth * 0.3) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.87, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
