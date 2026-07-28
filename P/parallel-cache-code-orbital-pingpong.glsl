#version 330 core
// Ping-pong radial color rings pulling cached frames around audio-driven orbits.

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

float ping_pong(float value, float size) {
    float wrapped = mod(value, size * 2.0);
    return wrapped <= size ? wrapped : size * 2.0 - wrapped;
}

vec3 acid_palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.28, 0.56, 0.91)));
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
    float mid = texture(spectrum0, 0.21).r;
    float treble = texture(spectrum0, 0.59).r;
    float air = texture(spectrum0, 0.83).r;
    float radius = length(point);
    float angle = atan(point.y, point.x) + time_f * (0.35 + treble * 0.5);
    float radial_fold = ping_pong(radius + time_f * (0.22 + bass * 0.25), 0.45);
    float wave = sin(radius * (12.0 + mid * 10.0) - time_f * (3.0 + bass * 4.0));

    vec3 procedural;
    procedural.r = sin(angle * 3.0 + radial_fold * 13.0 + wave * TAU);
    procedural.g = sin(angle * 4.0 - radial_fold * 10.0 + wave * 4.12);
    procedural.b = sin(angle * 5.0 + radial_fold * 15.0 - wave * 3.46);
    procedural = procedural * 0.5 + 0.5;

    vec2 live_uv = tc + vec2(cos(angle), sin(angle)) * wave * (0.02 + mid * 0.035);
    vec3 live = texture(samp, mirror_repeat(live_uv)).rgb;
    vec3 accum = mix(procedural, live, 0.42);
    float total_weight = 1.0;

    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.03);
        float old_mid = sample_history(i, 0.21);
        float old_high = sample_history(i, 0.59);
        vec2 orbit = vec2(cos(time_f * 0.4 + age), sin(time_f * 0.31 - age)) *
                     age * (0.004 + old_mid * 0.012);
        vec2 old_point = rotate_2d(age * (0.028 + old_high * 0.1)) * point;
        old_point *= 1.0 - old_bass * 0.045 * age;
        float old_radius = length(old_point);
        float old_fold = ping_pong(old_radius + age * (0.04 + old_bass * 0.1), 0.45);
        vec2 history_uv = old_point / vec2(aspect, 1.0) + center + orbit;
        history_uv += normalize(old_point + vec2(0.001)) * old_fold * old_high * 0.08;
        vec3 cached = sample_cache(i, history_uv).rgb;
        float weight = pow(0.8, age);
        accum += cached * acid_palette(old_fold * 1.8 + age * 0.08 + old_mid) * weight;
        total_weight += weight;
    }

    vec3 result = accum / total_weight;
    float ring = pow(0.5 + 0.5 * wave, 7.0);
    result += acid_palette(radial_fold * 2.0 - time_f * 0.08) * ring * (0.3 + air * 1.2);
    result = (result - 0.5) * (1.2 + amp_smooth * 0.3) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.88, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
