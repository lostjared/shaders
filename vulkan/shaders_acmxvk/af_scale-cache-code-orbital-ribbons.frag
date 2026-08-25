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

// af_scale-cache-code-orbital-ribbons
// Twisted ribbons orbiting an audio-reactive core.
#define EFFECT_ID 11
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
    if (index == 0)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (index == 1)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (index == 2)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (index == 3)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (index == 4)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (index == 5)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (index == 6)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

float sample_history(int index, float frequency) {
    if (index == 0)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (index == 1)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (index == 2)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (index == 3)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (index == 4)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (index == 5)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(6)))).r;
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
    float time = time_f;
    float field = 0.0;

#if EFFECT_ID == 0
    float nova = sin(radius * (34.0 + bass * 22.0) - time * 8.0);
    float rays = pow(abs(cos(angle * (10.0 + floor(treble * 7.0)) + time)), 10.0);
    float arches = cos(sqrt(point.x * point.x + 0.003) * 16.0 - point.y * 6.0);
    field = nova * 0.28 + rays * exp(-radius * 2.0) * 0.55 + arches * 0.17;
#elif EFFECT_ID == 1
    float cross_wave = sin(point.x * 16.0 + time * 5.0) + sin(point.y * 18.0 + time * 4.0);
    field = cross_wave * 0.18 + sin(angle * 6.0 - radius * 24.0 + time * 5.0) * 0.4;
#elif EFFECT_ID == 2
    vec2 glass = point;
    glass.x *= 1.0 + abs(point.y) * (1.8 + middle);
    field = sin(length(glass) * 29.0 - time * 5.0) * 0.35;
    field += exp(-abs(point.x) * (8.0 + middle * 7.0)) * cos(point.y * 19.0) * 0.35;
#elif EFFECT_ID == 3
    vec2 cell = hex_cell(point * (8.0 + treble * 4.0));
    float plate = pow(max(1.0 - length(cell) * 1.5, 0.0), 5.0);
    field = plate * 0.65 + sin(radius * (28.0 + bass * 18.0) - time * 6.0) * 0.3;
#elif EFFECT_ID == 4
    vec2 petal = kaleidoscope(point, 7.0 + floor(treble * 5.0));
    field = cos(atan(petal.y, petal.x) * 5.0 - length(petal) * 19.0) * 0.4;
    field += sin(length(petal - vec2(0.2, 0.0)) * 28.0 - time * 5.0) * 0.3;
#elif EFFECT_ID == 5
    float sonar = sin(radius * (31.0 + bass * 18.0) - time * 8.0);
    float spiral = sin(angle * 5.0 - radius * 17.0 + time * 3.0);
    field = sonar * 0.38 + spiral * 0.34;
#elif EFFECT_ID == 6
    float lattice_x = sin(point.x * 18.0 + sin(point.y * 7.0 - time) * 4.0);
    float lattice_y = sin(point.y * 17.0 + cos(point.x * 8.0 + time) * 4.0);
    field = (1.0 - abs(lattice_x * lattice_y)) * 0.55 + sin(radius * 27.0 - time * 6.0) * 0.25;
#elif EFFECT_ID == 7
    vec2 cell = hex_cell(rotate_2d(0.25) * point * 9.0);
    float facet = pow(max(1.0 - length(cell) * 1.6, 0.0), 7.0);
    field = facet * 0.7 + cos(atan(cell.y, cell.x) * 6.0) * facet * 0.2;
#elif EFFECT_ID == 8
    float rose = cos(angle * (8.0 + floor(treble * 5.0)) - radius * 13.0 + time * 2.0);
    field = pow(max(rose, 0.0), 5.0) * exp(-radius * 1.5) * 0.75;
    field += sin(radius * 27.0 - time * 6.0) * 0.25;
#elif EFFECT_ID == 9
    float fold = ping_pong(radius + time * (0.18 + bass * 0.2), 0.34);
    field = sin(fold * (42.0 + middle * 20.0)) * 0.48;
    field += cos(angle * 8.0 + floor(radius * 11.0) * 1.6) * 0.25;
#elif EFFECT_ID == 10
    vec2 grid = abs(fract((point + fbm(point * 4.0) * 0.05) * 10.0) - 0.5);
    float circuit = exp(-min(grid.x, grid.y) * (30.0 + treble * 24.0));
    field = circuit * 0.65 + sin(radius * 26.0 - time * 6.0) * 0.28;
#elif EFFECT_ID == 11
    float ribbon_a = sin(point.x * 15.0 + sin(point.y * 6.0 - time) * 5.0);
    float ribbon_b = cos(point.y * 14.0 + sin(point.x * 7.0 + time) * 4.0);
    field = (ribbon_a + ribbon_b) * 0.25 + sin(angle * 4.0 - radius * 17.0) * 0.2;
#elif EFFECT_ID == 12
    vec2 crystal = kaleidoscope(point, 6.0);
    float tunnel = sin(log(length(crystal) + 0.07) * (15.0 + bass * 6.0) - time * 5.0);
    field = tunnel * 0.4 + cos(atan(crystal.y, crystal.x) * 9.0) * 0.3;
#elif EFFECT_ID == 13
    float fault = tanh(sin(point.x * 8.0 + fbm(point * 4.0) * 6.0 + time) * 4.0);
    float aurora = sin(point.y * 16.0 + sin(point.x * 5.0 - time) * 4.0);
    field = fault * 0.3 + aurora * 0.32 + fbm(point * 5.0 - time * 0.1) * 0.18;
#elif EFFECT_ID == 14
    float hand_a = exp(-abs(sin(angle - floor(time * 2.0) * 0.2)) * radius * 25.0);
    float hand_b = exp(-abs(sin(angle + time * 0.31)) * radius * 34.0);
    field = (hand_a + hand_b) * 0.5 + sin(radius * 33.0 - floor(time * 3.0)) * 0.28;
#elif EFFECT_ID == 15
    vec2 cell = hex_cell((point + vec2(sin(time * 0.2), cos(time * 0.17)) * 0.03) * 10.0);
    float honey = smoothstep(0.5, 0.16, length(cell));
    field = honey * 0.65 + sin(radius * (25.0 + bass * 17.0) - time * 5.0) * 0.28;
#elif EFFECT_ID == 16
    float web = sin(angle * 11.0 + sin(radius * 15.0 - time * 2.0) * 2.0);
    field = pow(abs(web), 6.0) * 0.62 + sin(radius * (29.0 + bass * 17.0) - time * 7.0) * 0.3;
#elif EFFECT_ID == 17
    float helix_a = sin(angle * 5.0 - radius * 21.0 - time * 5.0);
    float helix_b = cos(angle * 4.0 + radius * 15.0 - time * 3.0);
    field = helix_a * 0.38 + helix_b * 0.3 + fbm(point * 6.0 + time * 0.08) * 0.2;
#elif EFFECT_ID == 18
    float lotus = pow(max(cos(angle * 9.0 - radius * 13.0 + time * 2.0), 0.0), 5.0);
    field = lotus * exp(-radius * 1.6) * 0.72;
    field += sin(radius * (29.0 + bass * 20.0) - time * 7.0) * 0.28;
#elif EFFECT_ID == 19
    float tide = sin(point.x * 11.0 + sin(point.y * 8.0 + time) * 3.0);
    tide *= cos(point.y * 13.0 - cos(point.x * 6.0 - time) * 3.0);
    field = tide * 0.37 + exp(-radius * 2.4) * 0.3;
#elif EFFECT_ID == 20
    vec2 diamond = abs(fract(rotate_2d(PI * 0.25) * point * 9.0) - 0.5);
    float facets = 1.0 - smoothstep(0.12, 0.28, diamond.x + diamond.y);
    field = facets * 0.62 + sin(point.y * 25.0 + sin(point.x * 8.0 - time) * 4.0) * 0.27;
#elif EFFECT_ID == 21
    vec2 maze = abs(fract((rotate_2d(0.24) * point) * 8.0) - 0.5);
    float walls = 1.0 - smoothstep(0.04, 0.13, min(maze.x, maze.y));
    field = walls * 0.62 + cos(angle * 8.0 + floor(radius * 10.0) * 1.7) * 0.25;
#elif EFFECT_ID == 22
    float spokes = pow(abs(sin(angle * 12.0 - radius * 18.0 + time * 2.0)), 8.0);
    field = spokes * exp(-radius * 1.3) * 0.7;
    field += sin(radius * (25.0 + bass * 22.0) - time * 7.0) * 0.3;
#elif EFFECT_ID == 23
    float well = sin(log(radius + 0.035) * (14.0 + bass * 7.0) - angle * 5.0 + time * 4.0);
    field = well * 0.48 + exp(-radius * 5.0) * 0.5;
#else
    float crown = pow(abs(cos(angle * (13.0 + floor(treble * 7.0)) + time)), 12.0);
    float ring = sin(radius * (37.0 + bass * 24.0) - time * 9.0);
    field = crown * exp(-radius * 1.7) * 0.72 + ring * 0.32;
#endif

    return field + (fbm(point * 3.1 - vec2(0.0, time * 0.12)) - 0.5) * 0.12;
}

vec2 cache_transform(vec2 uv, vec2 center, float age, float bass, float middle, float treble,
                     vec2 flow) {
    vec2 point = uv - center;
    float ripple = sin((point.x + point.y) * (9.0 + float(EFFECT_ID % 7)) +
                       time_f * (2.0 + bass * 3.0) - age);
    float scale = pow(max(0.982 - bass * 0.065, 0.45), age);
    float twist = (0.014 + treble * 0.085) * age;

#if EFFECT_ID % 5 == 0
    point = rotate_2d(twist + ripple * 0.025) * point * scale;
    point += flow * age * (0.007 + middle * 0.012);
#elif EFFECT_ID % 5 == 1
    point = kaleidoscope(rotate_2d(twist * 0.6) * point, 5.0 + float(EFFECT_ID % 7));
    point *= scale;
    point += vec2(ripple) * age * 0.003;
#elif EFFECT_ID % 5 == 2
    point.x += sin(point.y * 14.0 + age + time_f) * (0.006 + middle * 0.014) * age;
    point.y += cos(point.x * 12.0 - age + time_f) * (0.005 + treble * 0.011) * age;
    point *= scale;
#elif EFFECT_ID % 5 == 3
    point = rotate_2d(-twist) * point;
    point.x *= 1.0 + age * (0.01 + middle * 0.016);
    point.y *= scale;
    point += normalize(point + vec2(0.001)) * ripple * 0.008;
#else
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
    float field = effect_field(point, bass, middle, treble);

    float pixel = 2.0 / max(max(resolution.x, resolution.y), 360.0);
    vec2 gradient = vec2(effect_field(point + vec2(pixel, 0.0), bass, middle, treble) - field,
                         effect_field(point + vec2(0.0, pixel), bass, middle, treble) - field) /
                    pixel;
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

    for (int index = 0; index < 8; ++index) {
        float age = float(index + 1);
        float old_bass = sample_history(index, 0.03);
        float old_middle = sample_history(index, 0.22);
        float old_treble = sample_history(index, 0.58);
        vec2 history_uv =
            cache_transform(tc, center, age, old_bass, old_middle, old_treble, surface_normal.xy);
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
