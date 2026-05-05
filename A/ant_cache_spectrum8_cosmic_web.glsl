#version 330 core
// ant_cache_spectrum8_cosmic_web
// Holographic fringe x game_ant_cosmic_web starfield twinkle + filament lattice
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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    vec3 acc = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        float h  = specHist(i, 0.05 + float(i) * 0.06);
        float h2 = specHist(i, 0.55);
        float ang = float(i) * 0.4 + h2 * 3.0;
        vec2 dir = vec2(cos(ang), sin(ang));
        float fringe = sin(dot(uv, dir) * (40.0 + h * 80.0) + iTime * (1.0 + h * 4.0));
        fringe = pow(fringe * 0.5 + 0.5, 4.0);
        vec2 suv = tc + dir * fringe * 0.04 * (1.0 + h);

        vec3 c;
        c.r = cacheHist(i, suv + vec2(h * 0.08, 0.0)).r;
        c.g = cacheHist(i, suv).g;
        c.b = cacheHist(i, suv - vec2(h * 0.08, 0.0)).b;
        vec3 tint = palette(float(i) * 0.13 + h * 4.0, vec3(0.0, 0.33, 0.66));
        acc += (c + tint * fringe * 0.45) * (1.0 + h * 4.5) * pow(0.84, float(i));
    }
    acc /= 3.0;

    // Cosmic web overlay: twinkling starfield + filament sin lattice
    float bass = texture(spectrum0, 0.04).r;
    float air  = texture(spectrum0, 0.85).r;
    vec2 g = floor(tc * iResolution / 4.0);
    float hg = hash(g);
    float twinkle = step(0.972 - air * 0.02, hg) * (0.5 + 0.5 * sin(iTime * 2.0 + hg * 30.0));
    vec3 starCol = vec3(0.7, 0.85, 1.0) * twinkle * (1.0 + bass * 4.0);

    // Filaments – several sin lattices at history-driven scales
    float web = 0.0;
    for (int k = 0; k < 4; k++) {
        float s = 14.0 + float(k) * 6.0 + specHist(k * 2, 0.3) * 30.0;
        float w = sin(uv.x * s + iTime * 0.3) * sin(uv.y * s - iTime * 0.27);
        web += smoothstep(0.7, 1.0, w);
    }
    web *= 0.18;
    vec3 webCol = vec3(0.6, 0.7, 1.0) * web * (0.7 + amp_smooth);

    vec3 outc = acc + starCol + webCol;
    outc *= 1.2 + amp_smooth * 1.0;
    // gentle vignette so stars pop
    vec2 vUV = tc * (1.0 - tc.yx);
    float vig = pow(vUV.x * vUV.y * 15.0, 0.18);
    outc *= mix(0.7, 1.05, vig);

    color = vec4(clamp(outc, 0.0, 1.0), 1.0);
}
