#version 330 core
// ant_cache_spectrum8_tunnel
// Recursive tunnel zoom where each ring is an older frame modulated by older spectrum
// Audio history (spectrum0..7) + Frame cache history (samp,samp1..samp8) - EXTREME

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

uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;
const float PI  = 3.14159265359;

float specHist(int i, float f) {
    if (i == 0) return texture(spectrum0, f).r;
    if (i == 1) return texture(spectrum1, f).r;
    if (i == 2) return texture(spectrum2, f).r;
    if (i == 3) return texture(spectrum3, f).r;
    if (i == 4) return texture(spectrum4, f).r;
    if (i == 5) return texture(spectrum5, f).r;
    if (i == 6) return texture(spectrum6, f).r;
    return texture(spectrum7, f).r;
}

vec4 cacheHist(int i, vec2 uv) {
    if (i == 0) return texture(samp,  uv);
    if (i == 1) return texture(samp1, uv);
    if (i == 2) return texture(samp2, uv);
    if (i == 3) return texture(samp3, uv);
    if (i == 4) return texture(samp4, uv);
    if (i == 5) return texture(samp5, uv);
    if (i == 6) return texture(samp6, uv);
    if (i == 7) return texture(samp7, uv);
    return texture(samp8, uv);
}

vec3 palette(float t, vec3 d) {
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0, 1.0, 1.0) * t + d));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float energy() {
    float e = 0.0;
    for (int i = 0; i < 8; i++) {
        e += specHist(i, 0.05) + specHist(i, 0.25) + specHist(i, 0.6);
    }
    return e / 24.0;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float bass   = texture(spectrum0, 0.03).r;
    float mid    = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air    = texture(spectrum0, 0.85).r;
    float e      = energy();

    float r = length(uv);
    float a = atan(uv.y, uv.x);
    vec3 acc = vec3(0.0);
    for (int i = 0; i < 9; i++) {
        float gen = float(i);
        float h_low = specHist(min(i, 7), 0.04);
        float h_hi  = specHist(min(i, 7), 0.6);
        float zoom = 1.0 - 0.12 * gen - h_low * 0.4;
        float rot = gen * 0.25 + h_hi * 3.0 + iTime * 0.5;
        float cs = cos(rot), sn = sin(rot);
        vec2 p = uv * (1.0 / max(zoom, 0.05));
        p = vec2(p.x * cs - p.y * sn, p.x * sn + p.y * cs);
        vec2 suv = p / vec2(aspect, 1.0) + 0.5;
        vec3 c = cacheHist(i, suv).rgb;
        c *= palette(gen * 0.1 + r - iTime * 0.2, vec3(0.0, 0.2, 0.5)) * (0.5 + h_low * 4.0);
        acc += c * pow(0.78, gen) * (1.0 + h_hi * 3.0);
    }
    acc /= 3.0;
    acc = mix(acc, 1.0 - acc, smoothstep(0.7, 1.0, amp_peak));
    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}
