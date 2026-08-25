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
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// Energy cache code: Tesla-coil spirals throw charged filaments across the room.
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

vec2 mirror_repeat(vec2 point) { return 1.0 - abs(mod(point, 2.0) - 1.0); }
vec3 palette(float phase) { return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.08, 0.39, 0.73))); }
vec3 sample_cache(int index, vec2 uv) { return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index)))).rgb; }
float history_fft(int index, float frequency) {
    int maximum_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, maximum_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

float vortex_field(vec2 point, float bass, float high) {
    float radius = max(length(point), 0.002);
    float angle = atan(point.y, point.x);
    float arms = 5.0 + floor(high * 5.0);
    float spiral = sin(angle * arms - radius * (28.0 - bass * 10.0) - time_f * (5.0 + bass * 5.0));
    float rings = sin(radius * (44.0 + high * 12.0) - time_f * 8.0);
    return 1.0 - abs(spiral * 0.62 + rings * 0.38);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 point = (tc - 0.5) * aspect;
    float bass = texture(spectrum0, 0.035).r;
    float middle = texture(spectrum0, 0.24).r;
    float high = texture(spectrum0, 0.68).r;
    float radius = max(length(point), 0.003);
    float energy = vortex_field(point, bass, high);
    vec2 tangent = vec2(-point.y, point.x) / radius;
    vec2 warp = tangent * energy * (0.018 + bass * 0.055) + point * sin(radius * 35.0 - time_f * 5.0) * 0.018;
    vec3 live = texture(samp, mirror_repeat(tc + warp / aspect)).rgb;
    live *= 0.8 + palette(energy + time_f * 0.08) * 0.75;
    live += palette(radius * 0.8 - time_f * 0.18) * pow(max(energy, 0.0), 6.0) * (1.0 + high * 2.5);

    vec3 accumulated = live;
    float total_weight = 1.0;
    for (int index = 0; index < SIZE; ++index) {
        float generation = float(index + 1);
        float age = generation / float(max(SIZE, 1));
        vec3 old_audio = vec3(history_fft(index, 0.035), history_fft(index, 0.24), history_fft(index, 0.68));
        float angle = generation * (0.035 + old_audio.z * 0.13);
        float cosine = cos(angle);
        float sine = sin(angle);
        mat2 rotation = mat2(cosine, -sine, sine, cosine);
        vec2 cache_point = rotation * point * (1.0 - age * (0.11 + old_audio.x * 0.1));
        cache_point += tangent * old_audio.y * age * 0.065;
        vec3 memory = sample_cache(index, cache_point / aspect + 0.5);
        memory *= palette(age * 0.7 + old_audio.z * 0.4 - time_f * 0.025);
        float weight = pow(0.76, generation) * (1.0 + old_audio.x * 0.45);
        accumulated += memory * weight;
        total_weight += weight;
    }
    vec3 result = accumulated / total_weight;
    result += palette(radius - time_f * 0.1) * pow(energy, 8.0) * (0.7 + amp_peak * 1.5);
    result = (result - 0.5) * (1.3 + amp_smooth * 0.25) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
