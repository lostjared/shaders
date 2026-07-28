#version 330 core
// Logarithmic auger carrying historical FFT energy down an eight-frame tunnel.

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

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.53 + 0.47 * cos(TAU * (phase + vec3(0.24, 0.57, 0.9)));
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
    float radius = length(point) + 0.002;
    float angle = atan(point.y, point.x);
    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.82).r;

    float depth = 1.0 / (radius + 0.045) + time_f * (1.8 + bass * 2.8);
    float blade = sin(angle * (9.0 + floor(treble * 6.0)) - depth * (3.2 + mid * 2.0));
    float teeth = cos(angle * 21.0 + depth * 5.4);
    float twist = angle + depth * (0.68 + bass * 0.25) + blade * 0.15;
    vec2 auger_uv = vec2(twist / TAU * 4.0 + teeth * 0.055,
                         depth * 0.32 + log(radius) * 0.72 + blade * 0.1);
    vec3 live = texture(samp, mirror_repeat(auger_uv)).rgb;
    vec3 accum = live;
    float total_weight = 1.0;

    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.03);
        float old_mid = sample_history(i, 0.22);
        float old_high = sample_history(i, 0.58);
        float old_air = sample_history(i, 0.82);
        float flow = age * (0.34 + old_bass * 1.4);
        float old_twist = twist + age * (0.07 + old_high * 0.26);
        vec2 history_uv = vec2(old_twist / TAU * 4.0 + flow * 0.08,
                               depth * 0.32 + log(radius) * 0.72 + flow);
        history_uv += vec2(sin(flow + time_f), cos(flow - time_f)) * old_mid * 0.075;
        vec3 cached = sample_cache(i, history_uv).rgb;
        cached.r *= 1.0 + old_mid * 0.35;
        cached.g *= 1.0 - old_bass * 0.18;
        cached.b *= 1.0 + old_air * 0.4;
        float weight = pow(0.8, age) * (0.75 + old_bass * 0.55);
        accum += cached * weight;
        total_weight += weight;
    }

    vec3 result = accum / total_weight;
    float blade_light = pow(0.5 + 0.5 * blade, 5.0);
    float tooth_light = pow(max(teeth, 0.0), 10.0);
    result = mix(result, result.bgr, 0.16 + blade_light * 0.3);
    result *= 0.55 + blade_light * (0.9 + mid) + abs(teeth) * 0.2;
    result += palette(depth * 0.025 + time_f * 0.05) * tooth_light * (0.2 + air);
    result = (result - 0.5) * (1.22 + amp_smooth * 0.3) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.87, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
