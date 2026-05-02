#version 330 core
// Spectrum Cache 3 — Frequency Prism Trails
// Each cache frame is split into R/G/B channels, each driven by a
// different spectrum band.  The three channels fan out in directions
// 120 degrees apart, with the spread controlled by the spectrum.
// Creates shimmering prismatic trails that dance with the music.

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

uniform sampler1D spectrum;
uniform vec2 iResolution;
uniform float time_f;

vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0)
        return texture(samp1, uv);
    if (idx == 1)
        return texture(samp2, uv);
    if (idx == 2)
        return texture(samp3, uv);
    if (idx == 3)
        return texture(samp4, uv);
    if (idx == 4)
        return texture(samp5, uv);
    if (idx == 5)
        return texture(samp6, uv);
    if (idx == 6)
        return texture(samp7, uv);
    return texture(samp8, uv);
}

void main(void) {
    vec4 current = texture(samp, tc);

    float bass = texture(spectrum, 0.04).r;
    float lowMid = texture(spectrum, 0.15).r;
    float mid = texture(spectrum, 0.30).r;
    float hiMid = texture(spectrum, 0.50).r;
    float treble = texture(spectrum, 0.70).r;
    float air = texture(spectrum, 0.88).r;

    // Three prism directions rotate with time, spectrum tilts the base angle
    float baseAngle = time_f * 0.5 + mid * 0.8;
    vec2 dirR = vec2(cos(baseAngle), sin(baseAngle));
    vec2 dirG = vec2(cos(baseAngle + 2.094), sin(baseAngle + 2.094));
    vec2 dirB = vec2(cos(baseAngle + 4.189), sin(baseAngle + 4.189));

    // Spread controlled by bass energy
    float spread = 0.004 + bass * 0.008;

    float rAccum = current.r;
    float gAccum = current.g;
    float bAccum = current.b;
    float rW = 1.0, gW = 1.0, bW = 1.0;

    for (int i = 0; i < 8; i++) {
        float age = float(i + 1);
        float decay = 1.0 / (1.0 + age * 0.35);

        // Each channel's spread is modulated by its own band
        float rSpread = spread * age * (0.5 + bass * 0.5);
        float gSpread = spread * age * (0.5 + mid * 0.5);
        float bSpread = spread * age * (0.5 + treble * 0.5);

        vec4 cR = sampleCache(i, tc + dirR * rSpread);
        vec4 cG = sampleCache(i, tc + dirG * gSpread);
        vec4 cB = sampleCache(i, tc + dirB * bSpread);

        // Weight each channel by spectrum energy at corresponding band
        float wR = decay * (0.4 + lowMid * 0.6);
        float wG = decay * (0.4 + hiMid * 0.6);
        float wB = decay * (0.4 + air * 0.6);

        rAccum += cR.r * wR;
        gAccum += cG.g * wG;
        bAccum += cB.b * wB;
        rW += wR;
        gW += wG;
        bW += wB;
    }

    vec3 prism = vec3(rAccum / rW, gAccum / gW, bAccum / bW);

    // Shimmer: high frequencies add a glitter overlay
    float shimmer = treble * sin(tc.x * iResolution.x * 0.5 + time_f * 6.0) * sin(tc.y * iResolution.y * 0.5 + time_f * 5.0);
    prism += shimmer * 0.08;

    // Blend with saturation boost driven by overall energy
    float energy = (bass + mid + treble) / 3.0;
    prism = mix(prism, prism * 1.15, energy * 0.5);

    color = vec4(prism, 1.0);
}
