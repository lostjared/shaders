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

// af_scale-cache-code-liquid-lattice-4D
// A fluid audio lattice tumbling through a 4D hyperplane.
#define EFFECT_ID 6
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

// --- 4D GEOMETRY MATRICES ---

vec4 rotate_4d_xw(vec4 v, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec4(v.x * c - v.w * s, v.y, v.z, v.x * s + v.w * c);
}

vec4 rotate_4d_yw(vec4 v, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec4(v.x, v.y * c - v.w * s, v.z, v.y * s + v.w * c);
}

vec4 rotate_4d_zw(vec4 v, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec4(v.x, v.y, v.z * c - v.w * s, v.z * s + v.w * c);
}

// Aggressive 4D to 2D projection. 
// A tight distance_w creates obvious "inside-out" folding.
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

float hash_21(vec2 point) {
    return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
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
        point = rotate_2d(0.71) * point * 2.03 + 1.37;
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
    float sector = TAU / sides;
    float angle = abs(mod(atan(point.y, point.x) + sector * 0.5, sector) - sector * 0.5);
    return vec2(cos(angle), sin(angle)) * radius;
}

vec3 palette(float phase) {
    float hue = float(EFFECT_ID) * 0.073;
    return 0.5 + 0.5 * cos(TAU * (phase + hue + vec3(0.02, 0.35, 0.69)));
}

vec3 tone_map(vec3 value) {
    value = max(value, 0.0);
    return clamp((value * (2.51 * value + 0.03)) /
                     (value * (2.43 * value + 0.59) + 0.14),
                 0.0, 1.0);
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

vec4 soft_sample(sampler2D image, vec2 uv, vec2 texel, float spread) {
    vec4 result = texture(image, mirror_repeat(uv)) * 4.0;
    result += texture(image, mirror_repeat(uv + vec2(texel.x, 0.0) * spread)) * 2.0;
    result += texture(image, mirror_repeat(uv - vec2(texel.x, 0.0) * spread)) * 2.0;
    result += texture(image, mirror_repeat(uv + vec2(0.0, texel.y) * spread)) * 2.0;
    result += texture(image, mirror_repeat(uv - vec2(0.0, texel.y) * spread)) * 2.0;
    result += texture(image, mirror_repeat(uv + texel * spread));
    result += texture(image, mirror_repeat(uv - texel * spread));
    result += texture(image, mirror_repeat(uv + vec2(texel.x, -texel.y) * spread));
    result += texture(image, mirror_repeat(uv + vec2(-texel.x, texel.y) * spread));
    return result / 16.0;
}

float effect_field(vec2 point, float bass, float middle, float treble, out float w_depth) {
    float time = time_f;
    
    // Construct 4D volume. The W axis oscillates rapidly to drive the folding.
    vec4 geo_4d = vec4(point.x, point.y, bass - middle, sin(time * 0.8) + treble);
    
    // Aggressive rotations to pull the Z and W axes into the X and Y view
    geo_4d = rotate_4d_xw(geo_4d, time * 0.9 + bass * 3.0);
    geo_4d = rotate_4d_yw(geo_4d, -time * 0.7 - middle * 2.0);
    geo_4d = rotate_4d_zw(geo_4d, time * 0.5 + treble * 1.5);
    
    // Export the W depth to drive the color palette later
    w_depth = geo_4d.w;
    
    // Squeeze the projection distance to make the folding violently obvious
    vec2 p2d = project_4d_to_2d(geo_4d, 1.4, 1.1);
    
    // Mix the original 2D coordinates with the 4D projection 
    // This anchors the effect so it doesn't entirely tear off the screen
    vec2 mix_point = mix(point, p2d, 0.75 + amp_peak * 0.25);
    
    float radius = length(mix_point) + 0.0001;
    float angle = atan(mix_point.y, mix_point.x);
    float field = 0.0;

#if EFFECT_ID == 6
    // The Liquid Lattice
    // Using the 4D projected coordinates forces the lattice lines to warp 
    // into impossible non-euclidean curves.
    float lattice_x = sin(mix_point.x * 18.0 + sin(mix_point.y * 7.0 - time) * 4.0);
    float lattice_y = sin(mix_point.y * 17.0 + cos(mix_point.x * 8.0 + time) * 4.0);
    
    // The W-depth alters the density of the lattice as it rotates
    field = (1.0 - abs(lattice_x * lattice_y)) * 0.55 + sin(radius * 27.0 - time * 6.0 + w_depth * 8.0) * 0.25;
#else
    // Fallback if EFFECT_ID is changed
    float crown = pow(abs(cos(angle * (13.0 + floor(treble * 7.0)) + time)), 12.0);
    float ring = sin(radius * (37.0 + bass * 24.0) - time * 9.0);
    field = crown * exp(-radius * 1.7) * 0.72 + ring * 0.32;
#endif

    return field + (fbm(mix_point * 3.1 - vec2(0.0, time * 0.12)) - 0.5) * 0.12;
}

// Optimized 4D cache transform taking precomputed angles
vec2 cache_transform_4d_opt(vec2 uv, vec2 center, float age, float old_bass, float old_treble, vec2 flow, 
                            float cos_xw, float sin_xw, float cos_yw, float sin_yw) {
    vec2 point = uv - center;
    
    // Embed history age into the W dimension
    vec4 cache_4d = vec4(point.x, point.y, old_bass - old_treble, (age * 0.15) * (1.0 + old_bass));
    
    // Apply SIMD-friendly precomputed rotations
    float nx = cache_4d.x * cos_xw - cache_4d.w * sin_xw;
    float nw = cache_4d.x * sin_xw + cache_4d.w * cos_xw;
    cache_4d.x = nx; 
    cache_4d.w = nw;
    
    float ny = cache_4d.y * cos_yw - cache_4d.w * sin_yw;
    nw = cache_4d.y * sin_yw + cache_4d.w * cos_yw;
    cache_4d.y = ny; 
    cache_4d.w = nw;
    
    // Flow distortion
    cache_4d.x += flow.x * age * 0.015;
    cache_4d.y += flow.y * age * 0.015;

    // Tight projection here forces the cache layers to "swallow" each other
    vec2 projected = project_4d_to_2d(cache_4d, 1.6, 1.3);
    
    // Kaleidoscope twist modulated by age and 4th dimension
    float twist = (0.014 + old_treble * 0.085) * age;
    projected = kaleidoscope(rotate_2d(twist * 0.6) * projected, 5.0 + float(EFFECT_ID % 7));
    
    float scale = pow(max(0.982 - old_bass * 0.065, 0.45), age);
    projected *= scale;
    
    return mirror_repeat(projected + center);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 texel = 1.0 / resolution;
    float aspect = resolution.x / resolution.y;
    vec2 mouse_uv = iMouse.xy / resolution;
    vec2 center = iMouse.z > 0.0 ? mouse_uv : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);

    float bass = texture(spectrum0, 0.03).r;
    float middle = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.82).r;
    
    float w_depth;
    float field = effect_field(point, bass, middle, treble, w_depth);

    float pixel = 2.0 / max(max(resolution.x, resolution.y), 360.0);
    
    float dummy_w;
    vec2 gradient = vec2(effect_field(point + vec2(pixel, 0.0), bass, middle, treble, dummy_w) - field,
                         effect_field(point + vec2(0.0, pixel), bass, middle, treble, dummy_w) - field) /
                    pixel;
    vec3 surface_normal = normalize(vec3(-gradient * (0.16 + amp_high * 0.05), 1.0));

    float ripple = sin(point.x * (10.0 + float(EFFECT_ID % 6)) + time_f * (4.0 + bass * 3.0));
    ripple += sin(point.y * (11.0 + float(EFFECT_ID % 5)) + time_f * (3.5 + middle * 2.0));
    vec2 radial = normalize(point + vec2(0.001));
    
    // W-depth drives the physical twist of the lens
    float twist = (length(point) - 0.7) * (0.6 + treble) + time_f * 0.12 + w_depth * 0.5;
    vec2 twisted_point = rotate_2d(twist) * point;
    vec2 twisted_uv = twisted_point / vec2(aspect, 1.0) + center;
    vec2 ripple_uv = tc + radial * ripple * (0.009 + bass * 0.018);
    vec2 live_uv = mirror_repeat(mix(ripple_uv, twisted_uv, 0.52) +
                                 surface_normal.xy * (0.012 + amp_low * 0.025));

    vec3 sharp = texture(samp, live_uv).rgb;
    vec3 softened = soft_sample(samp, live_uv, texel, 1.0 + middle * 3.0).rgb;
    float dispersion = 0.003 + treble * 0.014;
    vec3 refracted = vec3(texture(samp, mirror_repeat(live_uv + surface_normal.xy * dispersion)).r,
                          softened.g,
                          texture(samp, mirror_repeat(live_uv - surface_normal.xy * dispersion)).b);
    vec3 live = mix(sharp, refracted, 0.48 + amp_smooth * 0.15);

    float luminance = dot(live, vec3(0.299, 0.587, 0.114));
    
    // Color mapping is now entirely dependent on the 4D intersection
    vec3 mapped = 0.5 + 0.5 * cos(clamp(live, 0.0, 1.0) * PI * 0.5 +
                                  palette(field + time_f * 0.025 + w_depth * 1.5));
                                  
    vec3 accumulated = mix(live, mapped * (0.45 + luminance), 0.44);
    accumulated += palette(field * 0.55 + time_f * 0.04) *
                   pow(max(0.0, 1.0 - surface_normal.z), 2.0) * 0.7;
                   
    float total_weight = 1.0;

    // PRECOMPUTE TRANSCENDENTALS FOR CACHE LOOP
    float angle_xw = time_f * 1.2 + bass * 2.0;
    float cos_xw = cos(angle_xw);
    float sin_xw = sin(angle_xw);
    
    float angle_yw = -time_f * 0.8 + middle * 1.5;
    float cos_yw = cos(angle_yw);
    float sin_yw = sin(angle_yw);

    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1);
        float old_bass = sample_history(index, 0.03);
        float old_middle = sample_history(index, 0.22);
        float old_treble = sample_history(index, 0.58);
        
        vec2 history_uv = cache_transform_4d_opt(tc, center, age, old_bass, old_treble, surface_normal.xy,
                                                 cos_xw, sin_xw, cos_yw, sin_yw);
                                                 
        vec3 history_color = sample_cache(index, history_uv).rgb;
        float old_energy = old_bass * 0.5 + old_middle * 0.3 + old_treble * 0.2;
        
        // The hue of the trail echoes the W-depth folding of the main lattice
        vec3 history_tint = palette(field * 0.12 + w_depth * 0.2 + age * 0.061 + old_energy * 0.7);
        
        float weight = pow(0.76, age);
        accumulated += mix(history_color, history_color * history_tint, 0.62) * weight;
        total_weight += weight;
    }

    accumulated /= total_weight;
    float crest = pow(max(sin(field * 19.0 - time_f * 2.4 + w_depth * 4.0), 0.0), 7.0);
    accumulated += palette(field + time_f * 0.09) * crest * (0.25 + air * 1.35);
    accumulated = (accumulated - 0.5) * (1.08 + amp_smooth * 0.28) + 0.5;
    accumulated = mix(accumulated, vec3(1.0) - accumulated, smoothstep(0.91, 1.0, amp_peak));

    color = vec4(tone_map(accumulated), texture(samp, live_uv).a);
}