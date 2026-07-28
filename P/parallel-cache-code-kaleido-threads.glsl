#version 330 core
// Audio-selected kaleidoscope facets crossed by temporal spiral threads.

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

vec2 kaleido_fold(vec2 point, float sides) {
    float radius = length(point);
    float sector = TAU / sides;
    float angle = abs(mod(atan(point.y, point.x) + sector * 0.5, sector) - sector * 0.5);
    return vec2(cos(angle), sin(angle)) * radius;
}

vec3 acid_palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.12, 0.46, 0.79)));
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

    float bass = texture(spectrum0, 0.035).r;
    float mid = texture(spectrum0, 0.24).r;
    float treble = texture(spectrum0, 0.57).r;
    float air = texture(spectrum0, 0.82).r;
    float sides = 5.0 + floor(treble * 7.0);

    vec2 folded = kaleido_fold(rotate_2d(time_f * (0.12 + mid * 0.3)) * point, sides);
    float radius = length(folded) + 0.002;
    float angle = atan(folded.y, folded.x);
    float ping_pong = abs(mod(radius * (3.0 + bass * 2.0) + time_f * 0.3, 2.0) - 1.0);
    float thread_a = sin(angle * sides * 2.0 - radius * 24.0 + time_f * (3.0 + bass * 3.0));
    float thread_b = cos(angle * sides * 3.0 + ping_pong * 16.0 - time_f * 2.1);
    vec2 live_uv = mirror_repeat(folded * vec2(1.3, 1.8) + 0.5 +
                                  vec2(thread_a, thread_b) * (0.035 + mid * 0.04));
    vec3 live = texture(samp, live_uv).rgb;

    vec3 accum = live;
    float total_weight = 1.0;
    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.035);
        float old_mid = sample_history(i, 0.24);
        float old_high = sample_history(i, 0.57);
        vec2 old_fold = kaleido_fold(rotate_2d(age * (0.025 + old_high * 0.12)) * point,
                                     sides);
        old_fold *= pow(max(0.98 - old_bass * 0.05, 0.62), age);
        float old_radius = length(old_fold);
        float old_angle = atan(old_fold.y, old_fold.x);
        float weave = sin(old_angle * sides * 2.0 - old_radius * 22.0 + age + time_f);
        vec2 history_uv = old_fold * vec2(1.3, 1.8) + 0.5;
        history_uv += vec2(weave, -weave) * (0.025 + old_mid * 0.07);
        vec3 cached = sample_cache(i, history_uv).rgb;
        float weight = pow(0.78, age);
        accum += mix(cached, cached.gbr, old_high * 0.45) * weight;
        total_weight += weight;
    }

    vec3 result = accum / total_weight;
    float bright_thread = pow(0.5 + 0.5 * thread_a * thread_b, 6.0);
    result *= 0.72 + acid_palette(ping_pong + time_f * 0.06) * (0.5 + mid * 0.8);
    result += acid_palette(angle / TAU + air) * bright_thread * (0.45 + air * 1.2);
    result = (result - 0.5) * (1.2 + amp_smooth * 0.25) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
