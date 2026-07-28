#version 330 core
// Polar-Cartesian lattice with rippling historical frame cells.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;
uniform sampler1D spectrum0;
uniform sampler1D spectrum1;
uniform sampler1D spectrum2;
uniform sampler1D spectrum3;
uniform sampler1D spectrum4;
uniform sampler1D spectrum5;
uniform sampler1D spectrum6;
uniform sampler1D spectrum7;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;

mat2 rotate_2d(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.18, 0.51, 0.84)));
}

vec4 sample_cache(int index, vec2 uv) {
    uv = mirror_repeat(uv);
    if (index == 0) return texture(samp1, uv);
    if (index == 1) return texture(samp2, uv);
    if (index == 2) return texture(samp3, uv);
    if (index == 3) return texture(samp4, uv);
    if (index == 4) return texture(samp5, uv);
    if (index == 5) return texture(samp6, uv);
    if (index == 6) return texture(samp7, uv);
    return texture(samp8, uv);
}

float sample_history(int index, float frequency) {
    if (index == 0) return texture(spectrum1, frequency).r;
    if (index == 1) return texture(spectrum2, frequency).r;
    if (index == 2) return texture(spectrum3, frequency).r;
    if (index == 3) return texture(spectrum4, frequency).r;
    if (index == 4) return texture(spectrum5, frequency).r;
    if (index == 5) return texture(spectrum6, frequency).r;
    return texture(spectrum7, frequency).r;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.5 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);
    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.82).r;
    float radius = length(point) + 0.002;
    float angle = atan(point.y, point.x);

    float cells = 8.0 + floor(treble * 12.0);
    float radial_line = sin(radius * cells * TAU - time_f * (3.0 + bass * 4.0));
    float spoke_line = cos(angle * (6.0 + floor(mid * 6.0)) + time_f * 1.4);
    float lattice = radial_line * spoke_line;
    vec2 lattice_uv = tc + vec2(spoke_line, radial_line) * (0.025 + bass * 0.04);
    vec3 live = texture(samp, mirror_repeat(lattice_uv)).rgb;
    vec3 accum = live;
    float total_weight = 1.0;

    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.03);
        float old_mid = sample_history(i, 0.22);
        float old_high = sample_history(i, 0.58);
        vec2 old_point = rotate_2d(age * (0.018 + old_high * 0.09)) * point;
        old_point *= pow(max(0.985 - old_bass * 0.04, 0.7), age);
        float old_radius = length(old_point);
        float old_angle = atan(old_point.y, old_point.x);
        float row = floor(old_radius * cells + age * old_bass);
        float column = floor((old_angle / TAU + 0.5) * cells);
        vec2 jitter = vec2(sin(row + age), cos(column - age)) * old_mid * 0.025;
        vec2 history_uv = old_point / vec2(aspect, 1.0) + center + jitter;
        vec3 cached = sample_cache(i, history_uv).rgb;
        float weight = pow(0.79, age);
        accum += cached * palette((row + column) / cells + age * 0.06) * weight;
        total_weight += weight;
    }

    vec3 result = accum / total_weight;
    float edge = pow(0.5 + 0.5 * lattice, 8.0);
    result += palette(angle / TAU + radius + time_f * 0.04) * edge * (0.25 + air);
    result *= 0.82 + abs(lattice) * 0.4 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
