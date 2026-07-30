#version 330 core
// An audio-reactive, dynamically scaling trail.
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

// --- OPTIMIZED SAMPLERS (Supports infinite SIZE) ---

vec4 sample_cache(int index, vec2 uv) {
    uv = mirror_repeat(uv);
    // GLSL 330 natively accepts a dynamic float for the layer index
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    // Offset by 1 to match your original logic (index 0 fetched layer 1)
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(index + 1)))).r;
}

// --- AUDIO REACTIVE TRAIL TRANSFORM ---

vec2 dynamic_trail_transform(vec2 uv, vec2 center, int index, int total_layers, float bass, float treble, float time) {
    // 1. NORMALIZE: Where are we in the cache? (0.0 = newest, 1.0 = oldest)
    float progress = float(index) / float(max(total_layers - 1, 1));
    
    // 2. SCALE: Bass pushes the trail outward, progressing deeper into the screen
    float max_zoom = 1.0 + (bass * 1.5); 
    float current_scale = mix(1.0, max_zoom, progress);
    
    // 3. TWIST: Treble twists the trail, reversing direction slowly over time
    float max_angle = progress * (treble * PI) * sin(time * 0.5);
    mat2 rot = rotate_2d(max_angle);
    
    // Apply transformations around the center
    vec2 point = uv - center;
    point = rot * (point / current_scale);
    
    return mirror_repeat(point + center);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 mouse_uv = iMouse.xy / resolution;
    vec2 center = iMouse.z > 0.0 ? mouse_uv : vec2(0.5);

    // Fetch live audio
    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;

    // Sample the live frame
    vec3 live = texture(samp, tc).rgb;
    
    vec3 accumulated = live;
    float total_weight = 1.0;

    // Loop through the cache utilizing the dynamic SIZE macro
    for (int index = 0; index < SIZE; ++index) {
        
        // Fetch the historical audio for this specific layer
        float old_bass = sample_history(index, 0.03);
        float old_treble = sample_history(index, 0.58);
        
        // Warp the UVs based on audio and cache depth
        vec2 history_uv = dynamic_trail_transform(tc, center, index, SIZE, old_bass, old_treble, time_f);
        
        // Sample the warped history frame
        vec3 cached = sample_cache(index, history_uv).rgb;
        
        // Calculate dynamic weight (exponential fade)
        float progress = float(index) / float(max(SIZE - 1, 1));
        float weight = exp(-progress * 3.5); // 3.5 controls how fast the trail fades to black
        
        // Optional: Color shift the trail as it gets older
        vec3 trail_tint = mix(vec3(1.0), palette(time_f * 0.2 + progress + old_bass), progress * 0.8);
        
        accumulated += (cached * trail_tint) * weight;
        total_weight += weight;
    }

    // Average the accumulated layers
    vec3 result = accumulated / total_weight;
    
    // Final contrast and peak audio pump
    result = (result - 0.5) * (1.1 + amp_smooth * 0.2) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}