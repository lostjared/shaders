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

// --- OPTIMIZED SAMPLERS ---

vec4 sample_cache(int index, vec2 uv) {
    uv = mirror_repeat(uv);
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(index + 1)))).r;
}

// --- REALISTIC LENS TRANSFORM ---

vec2 dynamic_trail_transform(vec2 uv, vec2 center, int index, int total_layers, float bass, float treble, float time) {
    float progress = float(index) / float(max(total_layers - 1, 1));
    
    // Lens breathing: real cameras have a slight zoom shift when tracking bright objects or focusing
    float breath = sin(time * 0.8 + progress) * 0.015 * bass;
    float current_scale = 1.0 + (progress * breath);
    
    // Handheld organic drift instead of perfect geometric rotation
    vec2 drift = vec2(sin(time + progress * 2.0), cos(time * 1.3 + progress * 2.0));
    drift *= 0.008 * treble * progress;
    
    vec2 point = uv - center;
    point = (point / current_scale) + drift;
    
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

    // 1. SOLID LIVE FRAME
    vec3 live = texture(samp, tc).rgb;
    float live_lum = get_luminance(live);
    
    // 2. CALCULATE REALISTIC PHOSPHOR / SHUTTER TRAIL
    vec3 trail_accum = vec3(0.0);

    for (int index = 0; index < SIZE; ++index) {
        float old_bass = sample_history(index, 0.03);
        float old_treble = sample_history(index, 0.58);
        
        vec2 history_uv = dynamic_trail_transform(tc, center, index, SIZE, old_bass, old_treble, time_f);
        float progress = float(index) / float(max(SIZE - 1, 1));
        
        // Chromatic aberration based on the age of the frame (lens dispersion over time)
        float chroma_spread = progress * 0.012 * old_bass;
        vec3 cached;
        cached.r = sample_cache(index, history_uv + vec2(chroma_spread, 0.0)).r;
        cached.g = sample_cache(index, history_uv).g;
        cached.b = sample_cache(index, history_uv - vec2(chroma_spread, 0.0)).b;
        
        float cached_lum = get_luminance(cached);
        
        // MAGIC BULLET for realism: 
        // Bright pixels decay slowly (like glowing embers or headlights). 
        // Dark pixels decay immediately (so you don't get muddy grey ghosting).
        float decay_rate = mix(5.5, 1.2, cached_lum); 
        float physical_weight = exp(-progress * decay_rate);
        
        // Simulate film stock color shifting as light accumulates
        vec3 film_tint = mix(vec3(1.0), palette(time_f * 0.1 + progress + old_bass), progress * 0.4);
        
        trail_accum += (cached * film_tint) * physical_weight;
    }

    // Normalize and dial back the overall intensity of the trail
    vec3 trail = trail_accum / float(max(SIZE, 1));
    trail *= 1.8; // Boost the math back up to optical levels
    
    // 3. COMPOSITE
    // Max blending for light trails (simulating how light hits a physical sensor)
    // combined with a screen blend for the softer midtones.
    vec3 light_spill = max(live, trail * 0.8);
    vec3 screen_blend = live + trail - (live * trail);
    
    // Interpolate based on the brightness of the live frame to maintain sharp contrast
    vec3 result = mix(screen_blend, light_spill, live_lum);
    
    // Final contrast curve to ground the black levels
    result = (result - 0.5) * (1.08 + amp_smooth * 0.1) + 0.5;
    
    // Extreme audio peaks cause a brief negative flash
    result = mix(result, vec3(1.0) - result, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}