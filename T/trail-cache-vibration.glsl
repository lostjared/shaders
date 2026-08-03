#version 330 core
#define EFFECT_ID 24

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
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

// --- UTILITIES ---

mat2 rotate_2d(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.02, 0.35, 0.69)));
}

float get_luminance(vec3 col) {
    return dot(col, vec3(0.299, 0.587, 0.114));
}

// Random noise for jagged, mechanical vibration
float hash_21(vec2 point) {
    return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

// --- OPTIMIZED SAMPLERS ---

vec4 sample_cache(int index, vec2 uv) {
    uv = mirror_repeat(uv);
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(index + 1)))).r;
}

// --- VIOLENT TRAIL TRANSFORM ---

vec2 dynamic_trail_transform(vec2 uv, vec2 center, int index, int total_layers, float bass, float treble, float time, float peak) {
    float progress = float(index) / float(max(total_layers - 1, 1));
    
    // 1. High-frequency sine waves for rapid oscillation
    float shake_speed = time * 85.0 + float(index) * 5.0;
    vec2 wave_shake = vec2(sin(shake_speed), cos(shake_speed * 1.13));
    
    // 2. Chaotic noise for sudden, glitchy snaps
    float jitter_seed = time * 10.0 + float(index);
    vec2 noise_shake = vec2(hash_21(vec2(jitter_seed, 1.0)), hash_21(vec2(1.0, jitter_seed))) * 2.0 - 1.0;
    
    // 3. Combine and scale by audio intensity. 
    // The older the trail (progress), the more it violently detaches from the center.
    float vibration_magnitude = (bass * 0.15 + treble * 0.1 + peak * 0.1);
    vec2 total_vibration = (wave_shake * 0.4 + noise_shake * 0.6) * vibration_magnitude * progress;
    
    // Slight zoom to push the vibrating trail outward
    float current_scale = 1.0 + (progress * 0.05 * bass);
    
    vec2 point = uv - center;
    point = (point / current_scale) + total_vibration;
    
    return mirror_repeat(point + center);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 mouse_uv = iMouse.xy / resolution;
    vec2 center = iMouse.z > 0.0 ? mouse_uv : vec2(0.5);

    // Fetch live audio
    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;

    // 1. SOLID LIVE FRAME (Anchored so the image doesn't become total chaos)
    vec3 live = texture(samp, tc).rgb;
    float live_lum = get_luminance(live);
    
    // 2. CALCULATE VIBRATING TRAIL
    vec3 trail_accum = vec3(0.0);

    for (int index = 0; index < SIZE; ++index) {
        float old_bass = sample_history(index, 0.03);
        float old_treble = sample_history(index, 0.58);
        
        vec2 history_uv = dynamic_trail_transform(tc, center, index, SIZE, old_bass, old_treble, time_f, amp_peak);
        float progress = float(index) / float(max(SIZE - 1, 1));
        
        // The chromatic aberration ALSO vibrates heavily with the audio
        float chroma_vibrate = sin(time_f * 50.0 + float(index)) * 0.03 * old_bass;
        float chroma_spread = (progress * 0.01) + chroma_vibrate;
        
        vec3 cached;
        cached.r = sample_cache(index, history_uv + vec2(chroma_spread, 0.0)).r;
        cached.g = sample_cache(index, history_uv).g;
        cached.b = sample_cache(index, history_uv - vec2(chroma_spread, 0.0)).b;
        
        float cached_lum = get_luminance(cached);
        
        // Realistic decay: Bright pixels leave a trail, dark pixels do not
        float decay_rate = mix(6.0, 1.0, cached_lum); 
        float physical_weight = exp(-progress * decay_rate);
        
        // Color shift to make the vibrating trail look like overloaded analog film
        vec3 film_tint = mix(vec3(1.0), palette(time_f * 0.2 + progress + old_bass), progress * 0.6);
        
        trail_accum += (cached * film_tint) * physical_weight;
    }

    vec3 trail = trail_accum / float(max(SIZE, 1));
    
    // Overdrive the trail intensity during heavy bass drops
    trail *= 1.8 + (bass * 1.5);
    
    // 3. COMPOSITE
    vec3 light_spill = max(live, trail * 0.9);
    vec3 screen_blend = live + trail - (live * trail);
    
    // Bind the final look together based on luminance
    vec3 result = mix(screen_blend, light_spill, live_lum);
    
    // Final contrast curve
    result = (result - 0.5) * (1.1 + amp_smooth * 0.15) + 0.5;

    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}