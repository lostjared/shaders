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
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// psyche-bubble-cache-glitch-crystal
// Cache-recursive bubble psychedelia with live and historical FFT choreography.
#define PSYCHE_ID 22
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









const float PI = 3.14159265359;
const float TAU = 6.28318530718;

mat2 rotate_2d(float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return mat2(cosine, -sine, sine, cosine);
}

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

float hash_21(vec2 point) {
    return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 point) {
    vec2 cell = floor(point);
    vec2 part = fract(point);
    part = part * part * (3.0 - 2.0 * part);
    float lower = mix(hash_21(cell), hash_21(cell + vec2(1.0, 0.0)), part.x);
    float upper = mix(hash_21(cell + vec2(0.0, 1.0)), hash_21(cell + 1.0), part.x);
    return mix(lower, upper, part.y);
}

float fbm(vec2 point) {
    float result = 0.0;
    float weight = 0.5;
    for (int octave = 0; octave < 4; ++octave) {
        result += value_noise(point) * weight;
        point = rotate_2d(0.73) * point * 2.03 + vec2(1.7, 0.9);
        weight *= 0.5;
    }
    return result;
}

vec2 hex_cell(vec2 point) {
    vec2 scale = vec2(1.0, 1.7320508);
    vec2 first = mod(point, scale) - scale * 0.5;
    vec2 second = mod(point - scale * 0.5, scale) - scale * 0.5;
    return dot(first, first) < dot(second, second) ? first : second;
}

vec2 kaleidoscope(vec2 point, float sides) {
    float radius = length(point);
    float sector = TAU / max(sides, 2.0);
    float angle = abs(mod(atan(point.y, point.x) + sector * 0.5, sector) - sector * 0.5);
    return vec2(cos(angle), sin(angle)) * radius;
}

vec2 recursive_fold(vec2 point, float phase) {
    for (int fold = 0; fold < 4; ++fold) {
        point = abs(point) / max(dot(point, point), 0.18) - 0.72;
        point = rotate_2d(0.37 + phase * 0.03 + float(fold) * 0.11) * point;
    }
    return point;
}

vec2 voronoi_cell(vec2 point) {
    vec2 base = floor(point);
    vec2 part = fract(point);
    vec2 nearest = vec2(0.0);
    float nearest_distance = 8.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 random_point = vec2(hash_21(base + neighbor),
                                     hash_21(base + neighbor + 17.31));
            random_point = 0.5 + 0.42 * sin(time_f * 0.31 + TAU * random_point);
            vec2 difference = neighbor + random_point - part;
            float distance_squared = dot(difference, difference);
            if (distance_squared < nearest_distance) {
                nearest_distance = distance_squared;
                nearest = difference;
            }
        }
    }
    return nearest;
}

vec3 palette(float phase) {
    float identity = float(PSYCHE_ID);
    vec3 offset = vec3(0.03, 0.34, 0.67) +
                  identity * vec3(0.037, 0.053, 0.071);
    vec3 frequency = vec3(1.0, 1.13 + mod(identity, 3.0) * 0.09,
                          0.83 + mod(identity, 5.0) * 0.07);
    return 0.5 + 0.5 * cos(TAU * (phase * frequency + offset));
}

vec3 tone_map(vec3 value) {
    value = max(value, 0.0);
    return clamp((value * (2.51 * value + 0.03)) /
                     (value * (2.43 * value + 0.59) + 0.14),
                 0.0, 1.0);
}

vec4 sample_live(vec2 uv) {
    return texture(samp, mirror_repeat(uv));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history,
                   vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    return texture(spectrum_history,
                   vec2(clamp(frequency, 0.0, 1.0),
                        float(SPECTRUM_HISTORY_LAYER(index + 1)))).r;
}

// x is displacement phase, y is luminous structure, z is color phase.
vec3 psyche_field(vec2 point, float bass, float middle, float treble, float age) {
    float radius = length(point) + 0.0001;
    float angle = atan(point.y, point.x);
    float time = time_f;

    vec2 blocks = floor((point + 0.8) * vec2(15.0, 11.0));
    float random_phase = hash_21(blocks + floor(time * (3.0 + treble * 5.0)));
    float fault = sin(point.y * 33.0 + random_phase * TAU + age * 21.0);
    float shard = step(0.72 - bass * 0.2, random_phase) * pow(abs(fault), 7.0);
    return vec3(fault, shard, random_phase + age + point.x);
}

vec2 psyche_warp(vec2 uv, vec2 point, vec3 signal, float bass, float middle,
                 float treble, float age) {
    float radius = length(point) + 0.001;
    float angle = atan(point.y, point.x);
    vec2 radial = point / radius;
    vec2 tangent = vec2(-radial.y, radial.x);
    float depth = 0.25 + age * 0.75;

    vec2 block = floor((point + 0.8) * vec2(15.0, 11.0));
    vec2 jump = vec2(hash_21(block), hash_21(block + 7.3)) - 0.5;
    uv += jump * step(0.58, abs(signal.x)) * (0.035 + treble * 0.07) * depth;

    return uv;
}

float layer_gate(vec2 point, vec3 signal, float progress, int index) {
    float radius = length(point) + 0.0001;
    float angle = atan(point.y, point.x);
    float slot = float(index);

    return 0.22 + 0.78 * step(0.45 + progress * 0.25, hash_21(floor((point + 0.8) * 13.0) + slot));
}

vec3 memory_blend(vec3 live_color, vec3 memory, vec3 previous, int index,
                  float energy) {
    int family = PSYCHE_ID % 6;
    if (family == 0) {
        return memory;
    }
    if (family == 1) {
        return mix(memory, 1.0 - (1.0 - memory) * (1.0 - live_color),
                   0.35 + energy * 0.25);
    }
    if (family == 2) {
        return mix(memory, abs(memory - live_color) * 1.35, 0.3 + energy * 0.35);
    }
    if (family == 3) {
        return memory * (0.7 + live_color * 0.65);
    }
    if (family == 4) {
        vec3 shifted = (index % 3 == 0) ? memory.gbr :
                       ((index % 3 == 1) ? memory.brg : memory.rgb);
        return mix(memory, shifted, 0.35 + energy * 0.3);
    }
    return mix(memory, abs(memory - previous) + memory * 0.55,
               0.28 + energy * 0.3);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);

    float bass = max(texture(spectrum0, 0.035).r, amp_low);
    float middle = max(texture(spectrum0, 0.24).r, amp_mid);
    float treble = max(texture(spectrum0, 0.63).r, amp_high);

    vec3 live_signal = psyche_field(point, bass, middle, treble, 0.0);
    vec2 live_uv = psyche_warp(tc, point, live_signal, bass, middle, treble, 0.0);
    float chroma = 0.002 + treble * 0.018 + abs(live_signal.x) * 0.004;
    vec2 chroma_direction = vec2(cos(live_signal.z * TAU), sin(live_signal.z * TAU));

    vec3 live_color;
    live_color.r = sample_live(live_uv + chroma_direction * chroma).r;
    live_color.g = sample_live(live_uv).g;
    live_color.b = sample_live(live_uv - chroma_direction * chroma).b;
    live_color += palette(live_signal.z + time_f * 0.035) *
                  live_signal.y * (0.12 + amp_smooth * 0.22);

    vec3 accumulated = live_color * 1.25;
    float total_weight = 1.25;
    vec3 previous = live_color;

    for (int index = 0; index < SIZE; ++index) {
        float progress = float(index + 1) / float(max(SIZE, 1));
        float old_bass = sample_history(index, 0.035);
        float old_middle = sample_history(index, 0.24);
        float old_treble = sample_history(index, 0.63);
        float frequency_trace = sample_history(index,
                                               fract(0.08 + progress * 0.79));

        vec3 signal = psyche_field(point, old_bass, old_middle, old_treble,
                                   progress);
        vec2 history_uv = psyche_warp(tc, point, signal, old_bass, old_middle,
                                     old_treble, progress);
        vec3 memory = sample_cache(index, history_uv).rgb;

        vec3 tint = palette(signal.z + progress * 0.63 +
                            frequency_trace * 0.71);
        float saturation = 0.45 + old_middle * 0.55 + signal.y * 0.2;
        memory = mix(vec3(dot(memory, vec3(0.299, 0.587, 0.114))), memory,
                     saturation);
        memory *= 0.68 + tint * (0.46 + old_treble * 0.34);
        memory += tint * signal.y * (0.08 + frequency_trace * 0.2);
        memory = memory_blend(live_color, memory, previous, index,
                              old_bass + old_treble);

        float gate = layer_gate(point, signal, progress, index);
        float decay = 2.0 + float(PSYCHE_ID % 7) * 0.17;
        float weight = exp(-progress * decay) * gate *
                       (0.72 + frequency_trace * 0.5);
        accumulated += memory * weight;
        total_weight += weight;
        previous = memory;
    }

    vec3 result = accumulated / max(total_weight, 0.001);
    result = (result - 0.5) * (1.08 + amp_smooth * 0.32) + 0.5;

    int peak_mode = PSYCHE_ID % 4;
    float peak = smoothstep(0.84, 1.0, amp_peak);
    if (peak_mode == 0) {
        result = mix(result, 1.0 - result, peak * 0.85);
    } else if (peak_mode == 1) {
        result += palette(live_signal.z + 0.5) * peak * 0.28;
    } else if (peak_mode == 2) {
        result = mix(result, result.brg, peak * 0.72);
    } else {
        result = mix(result, result * result * (3.0 - 2.0 * result),
                     peak * 0.8);
    }

    color = vec4(tone_map(result), sample_live(tc).a);
}
