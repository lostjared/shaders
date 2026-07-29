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
    switch(index) {
        case 0: return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
        case 1: return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
        case 2: return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
        case 3: return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
        case 4: return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
        case 5: return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
        case 6: return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
        default: return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
    }
}

float sample_history(int index, float frequency) {
    switch(index) {
        case 0: return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(1)))).r;
        case 1: return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(2)))).r;
        case 2: return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(3)))).r;
        case 3: return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(4)))).r;
        case 4: return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(5)))).r;
        case 5: return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(6)))).r;
        default: return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(7)))).r;
    }
}

vec4 soft_sample(sampler2D image, vec2 uv, vec2 texel, float spread) {
    vec2 offset_x = vec2(texel.x * spread, 0.0);
    vec2 offset_y = vec2(0.0, texel.y * spread);
    vec2 offset_xy = texel * spread;
    vec2 offset_x_ny = vec2(texel.x, -texel.y) * spread;

    vec4 result = texture(image, mirror_repeat(uv)) * 4.0;
    result += texture(image, mirror_repeat(uv + offset_x)) * 2.0;
    result += texture(image, mirror_repeat(uv - offset_x)) * 2.0;
    result += texture(image, mirror_repeat(uv + offset_y)) * 2.0;
    result += texture(image, mirror_repeat(uv - offset_y)) * 2.0;
    result += texture(image, mirror_repeat(uv + offset_xy));
    result += texture(image, mirror_repeat(uv - offset_xy));
    result += texture(image, mirror_repeat(uv + offset_x_ny));
    result += texture(image, mirror_repeat(uv - offset_x_ny));
    return result / 16.0;
}

float effect_field(vec2 point, float bass, float middle, float treble) {
    float radius = length(point) + 0.0001;
    float angle = atan(point.y, point.x);
    float time = time_f;
    float field = 0.0;

#if EFFECT_ID == 24
    float crown = pow(abs(cos(angle * (13.0 + floor(treble * 7.0)) + time)), 12.0);
    float ring = sin(radius * (37.0 + bass * 24.0) - time * 9.0);
    field = crown * exp(-radius * 1.7) * 0.72 + ring * 0.32;
#else
    // Fallback block removed for brevity, keeps your specific logic intact based on macros
    field = sin(radius * 10.0 - time); 
#endif

    return field + (fbm(point * 3.1 - vec2(0.0, time * 0.12)) - 0.5) * 0.12;
}

vec2 cache_transform(vec2 uv, vec2 center, float age, float bass, float middle, float treble, vec2 flow) {
    vec2 point = uv - center;
    float ripple = sin((point.x + point.y) * (9.0 + float(EFFECT_ID % 7)) +
                       time_f * (2.0 + bass * 3.0) - age);
    float scale = pow(max(0.982 - bass * 0.065, 0.45), age);
    float twist = (0.014 + treble * 0.085) * age;

#if EFFECT_ID % 5 == 4
    float radius = length(point);
    point = rotate_2d(twist + sin(radius * 16.0 - time_f) * 0.035 * age) * point * scale;
    point += normalize(point + vec2(0.001)) * bass * 0.012 * age;
#endif

    return mirror_repeat(point + center);
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
    
    // Core field calculated once
    float field = effect_field(point, bass, middle, treble);

    // Hardware derivatives used for immediate, cheap normal calculation
    float pixel_scale = max(max(resolution.x, resolution.y), 360.0) / 2.0;
    vec2 gradient = vec2(dFdx(field), dFdy(field)) * pixel_scale;
    vec3 surface_normal = normalize(vec3(-gradient * (0.16 + amp_high * 0.05), 1.0));

    float ripple = sin(point.x * (10.0 + float(EFFECT_ID % 6)) + time_f * (4.0 + bass * 3.0));
    ripple += sin(point.y * (11.0 + float(EFFECT_ID % 5)) + time_f * (3.5 + middle * 2.0));
    vec2 radial = normalize(point + vec2(0.001));
    float twist = (length(point) - 0.7) * (0.6 + treble) +
                  time_f * (0.12 + float(EFFECT_ID % 4) * 0.035);
    
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
    vec3 mapped = 0.5 + 0.5 * cos(clamp(live, 0.0, 1.0) * PI * 0.5 +
                                  palette(field + time_f * 0.025));
    vec3 accumulated = mix(live, mapped * (0.45 + luminance), 0.44);
    
    accumulated += palette(field * 0.55 + time_f * 0.04) *
                   pow(max(0.0, 1.0 - surface_normal.z), 2.0) * 0.7;
                   
    float total_weight = 1.0;

    // Temporal accumulation loop
    for (int index = 0; index < 8; ++index) {
        float age = float(index + 1);
        float old_bass = sample_history(index, 0.03);
        float old_middle = sample_history(index, 0.22);
        float old_treble = sample_history(index, 0.58);
        
        vec2 history_uv = cache_transform(tc, center, age, old_bass, old_middle, old_treble, surface_normal.xy);
        vec3 history = sample_cache(index, history_uv).rgb;
        
        float old_energy = old_bass * 0.5 + old_middle * 0.3 + old_treble * 0.2;
        vec3 history_tint = palette(field * 0.12 + age * 0.061 + old_energy * 0.7);
        float weight = pow(0.76, age);
        
        accumulated += mix(history, history * history_tint, 0.62) * weight;
        total_weight += weight;
    }

    accumulated /= total_weight;
    float crest = pow(max(sin(field * 19.0 - time_f * 2.4), 0.0), 7.0);
    accumulated += palette(field + time_f * 0.09) * crest * (0.25 + air * 1.35);
    accumulated = (accumulated - 0.5) * (1.08 + amp_smooth * 0.28) + 0.5;
    accumulated = mix(accumulated, vec3(1.0) - accumulated, smoothstep(0.91, 1.0, amp_peak));

    color = vec4(tone_map(accumulated), texture(samp, live_uv).a);
}