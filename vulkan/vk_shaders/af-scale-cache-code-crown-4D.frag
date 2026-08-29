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

// af_scale-cache-code-acid-crown-4D
// A crown of sharpened acid rays and 4D scale-pulsed reflections.
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

// --- 4D GEOMETRY OPERATIONS ---

// Rotates a vec4 in the XW plane
vec4 rotate_4d_xw(vec4 v, float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return vec4(v.x * cosine - v.w * sine, v.y, v.z, v.x * sine + v.w * cosine);
}

// Rotates a vec4 in the YW plane
vec4 rotate_4d_yw(vec4 v, float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return vec4(v.x, v.y * cosine - v.w * sine, v.z, v.y * sine + v.w * cosine);
}

// Rotates a vec4 in the ZW plane
vec4 rotate_4d_zw(vec4 v, float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return vec4(v.x, v.y, v.z * cosine - v.w * sine, v.z * sine + v.w * cosine);
}

// Projects 4D geometry back to 2D for texture sampling
vec2 project_4d_to_2d(vec4 v, float distance_z, float distance_w) {
    // Prevent division by zero with small offsets
    float w_proj = 1.0 / (distance_w - v.w + 0.001);
    float z_proj = 1.0 / (distance_z - (v.z * w_proj) + 0.001);
    return vec2(v.x * z_proj * w_proj, v.y * z_proj * w_proj);
}

mat2 rotate_2d(float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return mat2(cosine, -sine, sine, cosine);
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

float effect_field(vec2 point, float bass, float middle, float treble) {
    float radius = length(point) + 0.0001;
    float angle = atan(point.y, point.x);
    
    // Construct a 4D spatial coordinate using the audio spectrum for Z and W
    vec4 geo_4d = vec4(point.x, point.y, bass - middle, treble + sin(time_f * 0.2));
    
    // Rotate the 4D object based on time and audio intensity
    geo_4d = rotate_4d_xw(geo_4d, time_f * 0.6 + bass * 2.0);
    geo_4d = rotate_4d_yw(geo_4d, time_f * 0.4 - middle * 1.5);
    geo_4d = rotate_4d_zw(geo_4d, time_f * 0.2 + treble);
    
    // Use the 4D transformed vector to calculate the field intensity
    float crown = pow(abs(cos(angle * (13.0 + floor(treble * 7.0)) + time_f + geo_4d.w * 5.0)), 12.0);
    float ring = sin(radius * (37.0 + bass * 24.0) - time_f * 9.0 + geo_4d.z * 10.0);
    
    float field = crown * exp(-radius * 1.7) * 0.72 + ring * 0.32;
    return field + (fbm(vec2(geo_4d.x, geo_4d.y) * 3.1 - vec2(0.0, time_f * 0.12)) - 0.5) * 0.12;
}

vec2 cache_transform_4d(vec2 uv, vec2 center, float age, float bass, float middle, float treble, vec2 flow) {
    vec2 point = uv - center;
    
    // Embed the 2D cache coordinate into 4D space
    // Z axis maps to spectral energy, W axis maps to the layer's age in the cache
    vec4 cache_4d = vec4(point.x, point.y, bass - treble, age * 0.1);
    
    // Perform 4D hyper-rotations to warp the previous frames
    cache_4d = rotate_4d_xw(cache_4d, time_f * 0.3 + bass);
    cache_4d = rotate_4d_yw(cache_4d, -time_f * 0.2 + middle);
    
    // Add the surface normal flow into the 4D geometry
    cache_4d.x += flow.x * age * (0.007 + middle * 0.012);
    cache_4d.y += flow.y * age * (0.007 + middle * 0.012);

    // Project the 4D volume back down to 2D for the actual texture lookup
    vec2 projected = project_4d_to_2d(cache_4d, 2.5, 2.0);
    
    float scale = pow(max(0.982 - bass * 0.065, 0.45), age);
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
    
    float field = effect_field(point, bass, middle, treble);

    float pixel = 2.0 / max(max(resolution.x, resolution.y), 360.0);
    vec2 gradient = vec2(effect_field(point + vec2(pixel, 0.0), bass, middle, treble) - field,
                         effect_field(point + vec2(0.0, pixel), bass, middle, treble) - field) /
                    pixel;
    vec3 surface_normal = normalize(vec3(-gradient * (0.16 + amp_high * 0.05), 1.0));

    float ripple = sin(point.x * 10.0 + time_f * (4.0 + bass * 3.0));
    ripple += sin(point.y * 11.0 + time_f * (3.5 + middle * 2.0));
    vec2 radial = normalize(point + vec2(0.001));
    
    vec2 ripple_uv = tc + radial * ripple * (0.009 + bass * 0.018);
    vec2 live_uv = mirror_repeat(ripple_uv + surface_normal.xy * (0.012 + amp_low * 0.025));

    vec3 sharp = texture(samp, live_uv).rgb;
    vec3 softened = soft_sample(samp, live_uv, texel, 1.0 + middle * 3.0).rgb;
    float dispersion = 0.003 + treble * 0.014;
    vec3 refracted = vec3(texture(samp, mirror_repeat(live_uv + surface_normal.xy * dispersion)).r,
                          softened.g,
                          texture(samp, mirror_repeat(live_uv - surface_normal.xy * dispersion)).b);
    vec3 live = mix(sharp, refracted, 0.48 + amp_smooth * 0.15);

    float luminance = dot(live, vec3(0.299, 0.587, 0.114));
    
    // Map the 4D geometry directly to the color palette
    // We construct a vector from the field, spectrum, and time, rotate it, and use the projected value
    vec4 color_4d = vec4(field, bass, middle, time_f * 0.1);
    color_4d = rotate_4d_xw(color_4d, treble * PI);
    
    vec3 mapped = 0.5 + 0.5 * cos(clamp(live, 0.0, 1.0) * PI * 0.5 +
                                  palette(color_4d.x + color_4d.w));
                                  
    vec3 accumulated = mix(live, mapped * (0.45 + luminance), 0.44);
    accumulated += palette(field * 0.55 + time_f * 0.04) *
                   pow(max(0.0, 1.0 - surface_normal.z), 2.0) * 0.7;
    float total_weight = 1.0;

    for (int index = 0; index < 8; ++index) {
        float age = float(index + 1);
        float old_bass = sample_history(index, 0.03);
        float old_middle = sample_history(index, 0.22);
        float old_treble = sample_history(index, 0.58);
        
        // Use the new 4D transform for the cache history lookup
        vec2 history_uv = cache_transform_4d(tc, center, age, old_bass, old_middle, old_treble, surface_normal.xy);
        
        vec3 history_color = sample_cache(index, history_uv).rgb;
        float old_energy = old_bass * 0.5 + old_middle * 0.3 + old_treble * 0.2;
        
        // Shift the tint utilizing the 4D geometry mapping from earlier
        vec3 history_tint = palette(color_4d.z * 0.12 + age * 0.061 + old_energy * 0.7);
        
        float weight = pow(0.76, age);
        accumulated += mix(history_color, history_color * history_tint, 0.62) * weight;
        total_weight += weight;
    }

    accumulated /= total_weight;
    float crest = pow(max(sin(field * 19.0 - time_f * 2.4), 0.0), 7.0);
    accumulated += palette(field + time_f * 0.09) * crest * (0.25 + air * 1.35);
    accumulated = (accumulated - 0.5) * (1.08 + amp_smooth * 0.28) + 0.5;
    accumulated = mix(accumulated, vec3(1.0) - accumulated, smoothstep(0.91, 1.0, amp_peak));

    color = vec4(tone_map(accumulated), texture(samp, live_uv).a);
}