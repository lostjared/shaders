#version 330 core
// ripple-cache-loom-crown-opal-vortex
// An opalescent vortex crowned by audio-cut radial teeth.
#define EFFECT_ID 7

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
    float hue = float(EFFECT_ID) * 0.071;
    return 0.5 + 0.5 * cos(TAU * (phase + hue + vec3(0.03, 0.36, 0.68)));
}

vec3 tone_map(vec3 value) {
    value = max(value, 0.0);
    return clamp((value * (2.51 * value + 0.03)) /
                     (value * (2.43 * value + 0.59) + 0.14),
                 0.0, 1.0);
}

vec2 mirror_gradient(vec2 uv, vec2 screen_gradient) {
    // Remove period-sized jumps before selecting a mip level at polar wrap seams.
    vec2 periodic_gradient = screen_gradient - round(screen_gradient * 0.5) * 2.0;
    vec2 direction = vec2(1.0) - 2.0 * step(vec2(1.0), mod(uv, 2.0));
    return periodic_gradient * direction;
}

vec4 sample_live(vec2 uv) {
    vec2 gradient_x = mirror_gradient(uv, dFdx(uv));
    vec2 gradient_y = mirror_gradient(uv, dFdy(uv));
    return textureGrad(samp, mirror_repeat(uv), gradient_x, gradient_y);
}

vec4 sample_cache_layer(vec2 uv, float layer) {
    vec2 gradient_x = mirror_gradient(uv, dFdx(uv));
    vec2 gradient_y = mirror_gradient(uv, dFdy(uv));
    return textureGrad(history, vec3(mirror_repeat(uv), layer), gradient_x, gradient_y);
}

vec4 sample_cache(int index, vec2 uv) {
    if (index == 0) return sample_cache_layer(uv, float(CACHE_HISTORY_LAYER(0)));
    if (index == 1) return sample_cache_layer(uv, float(CACHE_HISTORY_LAYER(1)));
    if (index == 2) return sample_cache_layer(uv, float(CACHE_HISTORY_LAYER(2)));
    if (index == 3) return sample_cache_layer(uv, float(CACHE_HISTORY_LAYER(3)));
    if (index == 4) return sample_cache_layer(uv, float(CACHE_HISTORY_LAYER(4)));
    if (index == 5) return sample_cache_layer(uv, float(CACHE_HISTORY_LAYER(5)));
    if (index == 6) return sample_cache_layer(uv, float(CACHE_HISTORY_LAYER(6)));
    return sample_cache_layer(uv, float(CACHE_HISTORY_LAYER(7)));
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

vec3 soft_sample(vec2 uv, vec2 texel, float spread) {
    vec3 result = sample_live(uv).rgb * 4.0;
    result += sample_live(uv + vec2(texel.x, 0.0) * spread).rgb * 2.0;
    result += sample_live(uv - vec2(texel.x, 0.0) * spread).rgb * 2.0;
    result += sample_live(uv + vec2(0.0, texel.y) * spread).rgb * 2.0;
    result += sample_live(uv - vec2(0.0, texel.y) * spread).rgb * 2.0;
    return result / 12.0;
}

float crown_field(vec2 point, float bass, float middle, float treble) {
    float radius = length(point) + 0.0001;
    float angle = atan(point.y, point.x);
    float time = time_f;
    float field = 0.0;

#if EFFECT_ID == 0
    float rays = pow(abs(cos(angle * (11.0 + floor(treble * 6.0)) + time)), 11.0);
    field = rays * exp(-radius * 1.8) * 0.75 +
            sin(radius * (35.0 + bass * 22.0) - time * 8.0) * 0.31;
#elif EFFECT_ID == 1
    float thistle = cos(angle * 13.0 - radius * 18.0 + time * 2.3);
    field = sign(thistle) * pow(abs(thistle), 5.0) * exp(-radius * 1.3) * 0.68 +
            sin(radius * 31.0 - time * 6.0) * 0.27;
#elif EFFECT_ID == 2
    vec2 cell = hex_cell(rotate_2d(0.2 + time * 0.03) * point * (8.0 + treble * 4.0));
    float oracle = pow(max(1.0 - length(cell) * 1.65, 0.0), 7.0);
    field = oracle * 0.67 + cos(angle * 12.0 - radius * 24.0) * 0.29;
#elif EFFECT_ID == 3
    float tide = sin(radius * (29.0 + bass * 24.0) - time * 7.0);
    float diadem = pow(abs(sin(angle * 10.0 + tide)), 9.0);
    field = tide * 0.34 + diadem * exp(-radius * 1.5) * 0.64;
#elif EFFECT_ID == 4
    float aurora = sin(point.y * 17.0 + sin(point.x * 7.0 - time) * 5.0);
    float spindle = sin(angle * 7.0 - radius * 21.0 + time * 3.0);
    field = aurora * 0.3 + spindle * 0.4 + fbm(point * 4.0) * 0.18;
#elif EFFECT_ID == 5
    vec2 crystal = kaleidoscope(point, 7.0 + floor(treble * 4.0));
    field = sin(log(length(crystal) + 0.06) * (16.0 + bass * 7.0) - time * 5.0) * 0.43 +
            pow(abs(cos(angle * 9.0)), 10.0) * exp(-radius * 2.0) * 0.48;
#elif EFFECT_ID == 6
    float lattice_x = sin(point.x * 19.0 + sin(point.y * 8.0 - time) * 4.0);
    float lattice_y = sin(point.y * 18.0 + cos(point.x * 7.0 + time) * 4.0);
    field = (1.0 - abs(lattice_x * lattice_y)) * 0.55 +
            sin(radius * (30.0 + bass * 18.0) - time * 7.0) * 0.3;
#elif EFFECT_ID == 7
    float vortex = sin(angle * 6.0 - radius * (20.0 + middle * 10.0) + time * 4.0);
    float teeth = pow(abs(cos(angle * 14.0 + time)), 12.0);
    field = vortex * 0.43 + teeth * exp(-radius * 2.2) * 0.57;
#elif EFFECT_ID == 8
    float arches = cos(sqrt(point.x * point.x + 0.002) * 19.0 - abs(point.y) * 9.0);
    float relic = pow(max(cos(angle * 12.0 - radius * 8.0), 0.0), 7.0);
    field = arches * 0.34 + relic * exp(-radius * 1.4) * 0.65;
#elif EFFECT_ID == 9
    vec2 petal = kaleidoscope(rotate_2d(time * 0.08) * point, 9.0);
    float mercury = sin(length(petal - vec2(0.23, 0.0)) * (27.0 + bass * 13.0) - time * 6.0);
    field = mercury * 0.4 + cos(angle * 9.0 + radius * 15.0) * 0.3;
#elif EFFECT_ID == 10
    float thunder = sin(angle * 15.0 + fbm(point * 6.0) * 5.0 - radius * 19.0);
    field = sign(thunder) * pow(abs(thunder), 3.0) * exp(-radius * 1.2) * 0.6 +
            sin(radius * 38.0 - time * 10.0) * 0.33;
#elif EFFECT_ID == 11
    float velvet = sin(angle * 5.0 - radius * 23.0 - time * 4.0);
    float cyclone = cos(angle * 4.0 + radius * 16.0 - time * 2.7);
    field = velvet * 0.4 + cyclone * 0.31 + fbm(point * 5.0 + time * 0.07) * 0.2;
#elif EFFECT_ID == 12
    vec2 fold = abs(fract(rotate_2d(PI * 0.25) * point * 9.0) - 0.5);
    float forge = 1.0 - smoothstep(0.1, 0.29, fold.x + fold.y);
    field = forge * 0.62 + sin(radius * (32.0 + bass * 20.0) - time * 8.0) * 0.31;
#elif EFFECT_ID == 13
    vec2 grid = abs(fract((point + fbm(point * 4.0) * 0.04) * 10.0) - 0.5);
    float circuit = exp(-min(grid.x, grid.y) * (31.0 + treble * 22.0));
    field = circuit * 0.62 + cos(angle * 11.0 - radius * 18.0 + time) * 0.3;
#elif EFFECT_ID == 14
    float plasma = sin(point.x * 14.0 + sin(point.y * 7.0 - time) * 5.0) *
                   cos(point.y * 13.0 - cos(point.x * 6.0 + time) * 4.0);
    float coronet = pow(abs(cos(angle * 13.0 + time * 1.3)), 11.0);
    field = plasma * 0.38 + coronet * exp(-radius * 1.6) * 0.65;
#elif EFFECT_ID == 15
    float iris = sin(log(radius + 0.04) * (15.0 + bass * 8.0) - angle * 6.0 + time * 4.0);
    field = iris * 0.46 + (fbm(point * 7.0 - time * 0.12) - 0.5) * 0.37;
#elif EFFECT_ID == 16
    vec2 diamond = abs(fract(rotate_2d(PI * 0.25) * point * (8.0 + treble * 3.0)) - 0.5);
    float facets = 1.0 - smoothstep(0.12, 0.28, diamond.x + diamond.y);
    field = facets * 0.58 + sin(point.y * 24.0 + sin(point.x * 8.0 - time) * 5.0) * 0.31;
#elif EFFECT_ID == 17
    float nave = exp(-abs(point.x) * (7.0 + middle * 6.0)) * cos(point.y * 22.0);
    float arches = cos(sqrt(point.x * point.x + 0.004) * 18.0 - point.y * 7.0);
    field = nave * 0.47 + arches * 0.3 + pow(abs(cos(angle * 10.0)), 9.0) * 0.28;
#elif EFFECT_ID == 18
    float petals = pow(max(cos(angle * 14.0 - radius * 15.0 + time * 2.0), 0.0), 6.0);
    float static_noise = value_noise(floor(point * 45.0 + time * 7.0));
    field = petals * exp(-radius * 1.5) * 0.68 + (static_noise - 0.5) * 0.32;
#elif EFFECT_ID == 19
    float compass = pow(abs(sin(angle * 8.0 + time * 0.7)), 12.0);
    float molten = sin(radius * (28.0 + bass * 19.0) + sin(angle * 4.0) * 4.0 - time * 6.0);
    field = compass * exp(-radius * 1.5) * 0.66 + molten * 0.36;
#elif EFFECT_ID == 20
    vec2 shard = kaleidoscope(point, 6.0);
    float quartz = sin(length(shard - vec2(0.18, 0.0)) * 35.0 - time * 8.0);
    float tempest = sin(angle * 9.0 - radius * 24.0 + time * 5.0);
    field = quartz * 0.38 + tempest * 0.38 + fbm(point * 6.0) * 0.17;
#elif EFFECT_ID == 21
    float braid_a = sin(point.x * 17.0 + sin(point.y * 6.0 - time) * 5.0);
    float braid_b = cos(point.y * 16.0 + sin(point.x * 7.0 + time) * 5.0);
    field = (braid_a + braid_b) * 0.27 +
            pow(abs(cos(angle * 12.0)), 10.0) * exp(-radius * 1.7) * 0.55;
#elif EFFECT_ID == 22
    float vault = cos(sqrt(abs(point.x) + 0.01) * 15.0 - point.y * 9.0);
    float echo = sin(radius * (34.0 + bass * 17.0) - time * 7.0);
    field = vault * 0.34 + echo * 0.32 +
            pow(abs(sin(angle * 11.0)), 9.0) * exp(-radius * 1.8) * 0.52;
#elif EFFECT_ID == 23
    float lotus = pow(max(cos(angle * 10.0 - radius * 14.0 + time * 2.0), 0.0), 6.0);
    float ion = sin(radius * (39.0 + treble * 17.0) - time * 10.0);
    field = lotus * exp(-radius * 1.4) * 0.72 + ion * 0.31;
#else
    float abyss = sin(log(radius + 0.035) * (14.0 + bass * 7.0) - angle * 5.0 + time * 4.0);
    float tiara = pow(abs(cos(angle * (15.0 + floor(treble * 5.0)) + time)), 13.0);
    field = abyss * 0.42 + tiara * exp(-radius * 1.55) * 0.7;
#endif

    return field + (fbm(point * 3.2 - vec2(0.0, time * 0.12)) - 0.5) * 0.1;
}

vec2 cache_transform(vec2 uv, vec2 point, vec2 center, float age, float bass,
                     float middle, float treble, vec2 flow) {
    float radius = length(point) + 0.001;
    vec2 radial = point / radius;
    vec2 tangent = vec2(-radial.y, radial.x);
    float ripple = sin(radius * (18.0 + bass * 11.0) - age * 0.8 + time_f * 3.0);
    vec2 transformed = uv;

#if EFFECT_ID % 5 == 0
    transformed += tangent * age * (0.014 + middle * 0.04);
    transformed.y += ripple * age * (0.006 + bass * 0.012);
#elif EFFECT_ID % 5 == 1
    vec2 folded = kaleidoscope(point, 5.0 + float(EFFECT_ID % 7));
    transformed += folded * age * (0.018 + middle * 0.02);
    transformed.x += ripple * age * 0.009;
#elif EFFECT_ID % 5 == 2
    transformed.x += sin(transformed.y * TAU + age + time_f) * (0.018 + treble * 0.045);
    transformed.y += cos(transformed.x * TAU - age + time_f) * (0.014 + middle * 0.035);
#elif EFFECT_ID % 5 == 3
    transformed += radial * age * (0.018 + bass * 0.05);
    transformed += flow * age * (0.025 + middle * 0.04);
#else
    // Offset the periodic loom instead of rotating its absolute coordinates.
    vec2 swirl = rotate_2d(ripple * 0.025 * age) * tangent;
    transformed += swirl * age * (0.012 + middle * 0.018);
    transformed += tangent * age * (0.01 + treble * 0.035);
#endif

    return transformed;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 texel = 1.0 / resolution;
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.5 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);

    float bass = texture(spectrum0, 0.03).r;
    float middle = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.82).r;

    float seed = float(EFFECT_ID) * 0.173;
    vec2 source_a = vec2(sin(time_f * 0.31 + seed), cos(time_f * 0.43 - seed)) * 0.19;
    vec2 source_b = vec2(-sin(time_f * 0.53 - seed), sin(time_f * 0.29 + seed)) * 0.16;
    vec2 source_c = vec2(cos(time_f * 0.23 + seed), -cos(time_f * 0.61 + seed)) * 0.12;
    float wave_a = sin(length(point - source_a) * (21.0 + bass * 17.0) - time_f * 5.0);
    float wave_b = sin(length(point - source_b) * (18.0 + middle * 14.0) - time_f * 4.1);
    float wave_c = sin(length(point - source_c) * (24.0 + treble * 12.0) - time_f * 6.2);
    float interference = (wave_a + wave_b + wave_c) / 3.0;

    float field = crown_field(point, bass, middle, treble);
    float pixel = 2.0 / max(max(resolution.x, resolution.y), 360.0);
    vec2 gradient = vec2(
        crown_field(point + vec2(pixel, 0.0), bass, middle, treble) - field,
        crown_field(point + vec2(0.0, pixel), bass, middle, treble) - field) / pixel;
    vec3 surface_normal = normalize(vec3(-gradient * (0.13 + amp_high * 0.05), 1.0));

    float radius = length(point) + 0.001;
    float angle = atan(point.y, point.x);
    float crown_sides = 7.0 + float(EFFECT_ID % 9) + floor(treble * 4.0);
    float crown = pow(abs(cos(angle * crown_sides + time_f)), 10.0);
    float shuttle = abs(mod(radius * (2.0 + float(EFFECT_ID % 4) * 0.24) +
                            time_f * (0.28 + bass * 0.16), 1.0) - 0.5) * 2.0;
    float angular_repeat = 2.0 * (4.0 + float(EFFECT_ID % 8) + floor(treble * 3.0));
    vec2 loom_uv = vec2(angle / TAU * angular_repeat,
                        shuttle + interference * (0.13 + bass * 0.09));

#if EFFECT_ID % 5 == 0
    loom_uv += vec2(wave_a - wave_b, wave_b - wave_c) * 0.038;
#elif EFFECT_ID % 5 == 1
    // Swirl with a continuous offset so the polar period remains unchanged.
    vec2 swirl = rotate_2d(interference * 0.18) *
                 vec2(wave_a - wave_c, crown - 0.5);
    loom_uv += swirl * (0.035 + middle * 0.03);
    loom_uv.y += crown * 0.11;
#elif EFFECT_ID % 5 == 2
    loom_uv.x += sin(loom_uv.y * TAU + time_f) * (0.06 + middle * 0.09);
    loom_uv.y += field * 0.12;
#elif EFFECT_ID % 5 == 3
    loom_uv += surface_normal.xy * (0.08 + amp_low * 0.12);
    loom_uv.x += crown * interference * 0.13;
#else
    // Adding the fold preserves the even angular wrap across atan's branch cut.
    vec2 folded_offset = kaleidoscope(point, crown_sides) * 2.0;
    loom_uv += folded_offset * 0.22;
    loom_uv.y += sin(field * 8.0) * 0.07;
#endif

    vec2 live_uv = loom_uv + surface_normal.xy * (0.018 + amp_low * 0.03);
    float chroma = 0.003 + abs(interference) * 0.026 + treble * 0.018;
    vec3 sharp = sample_live(live_uv).rgb;
    vec3 softened = soft_sample(live_uv, texel, 1.0 + middle * 3.0);
    vec3 refracted = vec3(
        sample_live(live_uv + surface_normal.xy * chroma).r,
        softened.g,
        sample_live(live_uv - surface_normal.xy * chroma).b);
    vec3 live = mix(sharp, refracted, 0.48 + amp_smooth * 0.16);

    float luminance = dot(live, vec3(0.299, 0.587, 0.114));
    vec3 acid = palette(field * 0.18 + interference * 0.13 + time_f * 0.035);
    vec3 accumulated = mix(live, live * acid * (0.75 + luminance), 0.48);
    accumulated += palette(field + time_f * 0.06) * crown *
                   (0.08 + max(0.0, 1.0 - surface_normal.z) * 0.55);
    float total_weight = 1.0;

    for (int index = 0; index < 8; ++index) {
        float age = float(index + 1);
        float old_bass = sample_history(index, 0.03);
        float old_middle = sample_history(index, 0.22);
        float old_treble = sample_history(index, 0.58);
        vec2 history_uv = cache_transform(loom_uv, point, center, age, old_bass,
                                          old_middle, old_treble, surface_normal.xy);
        vec3 cached = sample_cache(index, history_uv).rgb;
        float old_energy = old_bass * 0.5 + old_middle * 0.3 + old_treble * 0.2;
        float thread = pow(abs(sin((history_uv.x + history_uv.y) * TAU +
                                   field * 2.0)), 5.0);
        vec3 tint = palette(field * 0.11 + age * 0.057 + old_energy * 0.65);
        float weight = pow(0.77, age) * (0.66 + thread * 0.42);
        accumulated += mix(cached, cached * tint, 0.6) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    float crest = pow(max(interference * 0.7 + field * 0.3, 0.0), 7.0);
    result += palette(radius + field * 0.2 + time_f * 0.1) * crest *
              (0.32 + air * 1.55);
    result = (result - 0.5) * (1.08 + amp_smooth * 0.3) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.91, 1.0, amp_peak));

    color = vec4(tone_map(result), sample_live(live_uv).a);
}
