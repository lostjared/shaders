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

// An audio-reactive, dynamically scaling glitch trail.
#define EFFECT_ID 24
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

// Pseudo-random noise for glitch artifacts
float hash_12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// --- OPTIMIZED SAMPLERS ---

vec4 sample_cache(int index, vec2 uv) {
    uv = mirror_repeat(uv);
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(index + 1)))).r;
}

// --- GLITCH TRAIL TRANSFORM ---

vec2 dynamic_trail_transform(vec2 uv, vec2 center, int index, int total_layers, float bass, float treble, float time, float peak) {
    float progress = float(index) / float(max(total_layers - 1, 1));
    
    // 1. SCANLINE TEARING: Horizontal block displacement on high audio peaks
    float strip_y = floor(uv.y * (20.0 + bass * 30.0) + time * 2.0);
    float tear_offset = (hash_12(vec2(strip_y, time)) - 0.5) * 2.0;
    
    // Activate tear only on loud peaks and push it deeper into the trail
    float tear_amount = step(0.65, peak) * progress * (treble * 0.15);
    vec2 point = uv - center;
    point.x += tear_offset * tear_amount;
    
    // 2. SCALE: Add slight noise to the zoom to make it breathe organically
    float max_zoom = 1.0 + (bass * 1.5) + (hash_12(uv * 0.1 + time) * 0.1 * progress); 
    float current_scale = mix(1.0, max_zoom, progress);
    
    // 3. STUTTER TWIST: Quantize the rotation for a robotic/VHS feel
    float raw_angle = progress * (treble * PI) * sin(time * 0.5);
    float quantize_steps = mix(40.0, 4.0, bass); // Heavy bass reduces steps, making it stutter more
    float stutter_angle = floor(raw_angle * quantize_steps) / quantize_steps;
    
    mat2 rot = rotate_2d(stutter_angle);
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

    vec3 live = texture(samp, tc).rgb;
    vec3 accumulated = live;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        
        float old_bass = sample_history(index, 0.03);
        float old_mid = sample_history(index, 0.22);
        float old_treble = sample_history(index, 0.58);
        
        float progress = float(index) / float(max(SIZE - 1, 1));
        
        // 4. TEMPORAL CHROMATIC ABERRATION: Split UVs based on treble and age
        float ca_spread = old_treble * progress * 0.04;
        
        vec2 uv_r = dynamic_trail_transform(tc + vec2(ca_spread, ca_spread * 0.5), center, index, SIZE, old_bass, old_treble, time_f, amp_peak);
        vec2 uv_g = dynamic_trail_transform(tc, center, index, SIZE, old_bass, old_treble, time_f, amp_peak);
        vec2 uv_b = dynamic_trail_transform(tc - vec2(ca_spread, ca_spread * 0.5), center, index, SIZE, old_bass, old_treble, time_f, amp_peak);
        
        // Sample split channels
        float r = sample_cache(index, uv_r).r;
        float g = sample_cache(index, uv_g).g;
        float b = sample_cache(index, uv_b).b;
        
        vec3 cached = vec3(r, g, b);
        
        // 5. SIGNAL DEGRADATION: Bitcrush the older layers based on mid frequencies
        float crush_steps = mix(64.0, 4.0, progress * old_mid);
        cached = floor(cached * crush_steps) / crush_steps;
        
        float weight = exp(-progress * 3.5); 
        
        vec3 trail_tint = mix(vec3(1.0), palette(time_f * 0.2 + progress + old_bass), progress * 0.8);
        
        accumulated += (cached * trail_tint) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    
    // Final contrast and inversion on heavy beats
    result = (result - 0.5) * (1.1 + amp_smooth * 0.2) + 0.5;
    
    // Violent invert flash when the beat peaks
    result = mix(result, vec3(1.0) - result, smoothstep(0.85, 1.0, amp_peak));

    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}