#version 330 core
// ant_cache_spectrum8_tremor_storm
// Holographic fringe x tremor2 sine quake distortion driven by spectrum bands
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
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0) * t + d));
}

float pingPong(float t, float maxT) {
    return abs(mod(t, 2.0 * maxT) - maxT);
}

vec2 tremor(vec2 uv, float freq, float amp, float phase) {
    float x = sin(uv.y * freq + iTime * 5.0 + phase) * amp;
    float y = cos(uv.x * freq + iTime * 5.0 + phase) * amp;
    return uv + vec2(x, y);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    vec3 acc = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        float h  = specHist(i, 0.05 + float(i) * 0.06);
        float h2 = specHist(i, 0.55);
        float bass = specHist(i, 0.04);

        float intervalFactor = pingPong(iTime, 2.0) / 2.0;
        float ampQ = (0.015 + bass * 0.08) * intervalFactor;
        vec2 suv = tremor(tc, 18.0 + h * 50.0, ampQ, float(i) * 0.7);

        // Holographic fringe
        float ang = float(i) * 0.4 + h2 * 3.0;
        vec2 dir = vec2(cos(ang), sin(ang));
        float fringe = sin(dot(uv, dir) * (40.0 + h * 80.0) + iTime * (1.0 + h * 4.0));
        fringe = pow(fringe * 0.5 + 0.5, 4.0);
        suv += dir * fringe * 0.06 * (1.0 + bass * 3.0);

        vec3 c;
        c.r = cacheHist(i, fract(suv) + vec2(h * 0.1, 0.0)).r;
        c.g = cacheHist(i, fract(suv)).g;
        c.b = cacheHist(i, fract(suv) - vec2(h * 0.1, 0.0)).b;

        vec3 tint = palette(float(i) * 0.13 + h * 4.0, vec3(0.0, 0.33, 0.66));
        acc += (c + tint * fringe * 0.6) * (1.0 + h * 5.0 + bass * 4.0) * pow(0.82, float(i));
    }
    acc /= 3.0;
    acc *= 1.3 + amp_peak * 1.4;
    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}
