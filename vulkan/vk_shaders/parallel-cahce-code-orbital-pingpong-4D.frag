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

// af_scale-cache-code-ping-pong-4D
// Ping-pong radial color rings tumbling through an audio-driven 4D hyperplane.
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

// --- 4D PROJECTION MATH ---
// A tight distance_w forces the extreme "inside-out" folding
vec2 project_4d_to_2d(vec4 v, float distance_z, float distance_w) {
    float w_proj = 1.0 / (distance_w - v.w + 0.001);
    float z_proj = 1.0 / (distance_z - (v.z * w_proj) + 0.001);
    return vec2(v.x * z_proj * w_proj, v.y * z_proj * w_proj);
}

mat2 rotate_2d(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

float ping_pong(float value, float size) {
    float wrapped = mod(value, size * 2.0);
    return wrapped <= size ? wrapped : size * 2.0 - wrapped;
}

vec3 acid_palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.28, 0.56, 0.91)));
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

// Optimized 4D Cache Transform
vec2 cache_transform_4d(vec2 point, float age, float old_bass, float old_mid, float old_high,
                        float cos_xw, float sin_xw, float cos_yw, float sin_yw,
                        vec2 center, float aspect, float time) {
                        
    // 1. Embed 2D coordinate into 4D space
    // Z is driven by spectrum difference, W maps to layer age
    vec4 cache_4d = vec4(point.x, point.y, old_bass - old_high, (age * 0.18) * (1.0 + old_bass));

    // 2. Apply inline SIMD rotations using precomputed angles
    float nx = cache_4d.x * cos_xw - cache_4d.w * sin_xw;
    float nw = cache_4d.x * sin_xw + cache_4d.w * cos_xw;
    cache_4d.x = nx;
    cache_4d.w = nw;

    float ny = cache_4d.y * cos_yw - cache_4d.w * sin_yw;
    nw = cache_4d.y * sin_yw + cache_4d.w * cos_yw;
    cache_4d.y = ny;
    cache_4d.w = nw;

    // 3. Orbit translation in 4D space
    cache_4d.x += cos(time * 0.4 + age) * age * (0.01 + old_mid * 0.02);
    cache_4d.y += sin(time * 0.31 - age) * age * (0.01 + old_mid * 0.02);

    // 4. Aggressive projection back to 2D
    // A distance_w of 1.3 combined with the age multiplier causes the inside-out fold
    vec2 projected = project_4d_to_2d(cache_4d, 1.6, 1.3);

    // 5. Apply the radial fold in the new projected space
    float proj_radius = length(projected);
    float fold = ping_pong(proj_radius + age * (0.04 + old_bass * 0.1), 0.45);
    
    // Scale and push coordinates to simulate depth tearing
    projected += normalize(projected + vec2(0.001)) * fold * old_high * 0.12;

    return projected / vec2(aspect, 1.0) + center;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.5 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);

    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.21).r;
    float treble = texture(spectrum0, 0.59).r;
    float air = texture(spectrum0, 0.83).r;
    
    float radius = length(point);
    float angle = atan(point.y, point.x) + time_f * (0.35 + treble * 0.5);
    float radial_fold = ping_pong(radius + time_f * (0.22 + bass * 0.25), 0.45);
    float wave = sin(radius * (12.0 + mid * 10.0) - time_f * (3.0 + bass * 4.0));

    // Base procedural layer
    vec3 procedural;
    procedural.r = sin(angle * 3.0 + radial_fold * 13.0 + wave * TAU);
    procedural.g = sin(angle * 4.0 - radial_fold * 10.0 + wave * 4.12);
    procedural.b = sin(angle * 5.0 + radial_fold * 15.0 - wave * 3.46);
    procedural = procedural * 0.5 + 0.5;

    vec2 live_uv = tc + vec2(cos(angle), sin(angle)) * wave * (0.02 + mid * 0.035);
    vec3 live = texture(samp, mirror_repeat(live_uv)).rgb;
    vec3 accum = mix(procedural, live, 0.42);
    
    float total_weight = 1.0;

    // PRECOMPUTE TRANSCENDENTALS
    // Drives the physical hyper-rotation of the entire cache block
    float angle_xw = time_f * 0.9 + bass * 1.5;
    float cos_xw = cos(angle_xw);
    float sin_xw = sin(angle_xw);

    float angle_yw = -time_f * 0.7 + mid * 1.2;
    float cos_yw = cos(angle_yw);
    float sin_yw = sin(angle_yw);

    for (int i = 0; i < SIZE; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.03);
        float old_mid = sample_history(i, 0.21);
        float old_high = sample_history(i, 0.59);
        
        // Transform the 2D coordinate through 4D space
        vec2 history_uv = cache_transform_4d(point, age, old_bass, old_mid, old_high,
                                             cos_xw, sin_xw, cos_yw, sin_yw,
                                             center, aspect, time_f);
                                             
        vec3 cached = sample_cache(i, history_uv).rgb;
        float weight = pow(0.8, age);
        
        // Maintain the radial color palette map, factoring in the age depth
        float old_radius = length((history_uv - center) * vec2(aspect, 1.0));
        float old_fold = ping_pong(old_radius + age * (0.04 + old_bass * 0.1), 0.45);
        
        accum += cached * acid_palette(old_fold * 1.8 + age * 0.08 + old_mid) * weight;
        total_weight += weight;
    }

    vec3 result = accum / total_weight;
    float ring = pow(0.5 + 0.5 * wave, 7.0);
    result += acid_palette(radial_fold * 2.0 - time_f * 0.08) * ring * (0.3 + air * 1.2);
    
    result = (result - 0.5) * (1.2 + amp_smooth * 0.3) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.88, 1.0, amp_peak));
    
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}