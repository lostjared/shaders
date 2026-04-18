#version 330 core
// Spectrum Cache 2 — Beat Smear
// Directional motion smear whose direction and length are driven by
// spectrum bands.  Bass pushes the smear outward from center, treble
// pulls it into a swirl.  Cache frames build up a trailing afterimage
// that pulses with the rhythm.

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
    if (idx == 0) return texture(samp1, uv);
    if (idx == 1) return texture(samp2, uv);
    if (idx == 2) return texture(samp3, uv);
    if (idx == 3) return texture(samp4, uv);
    if (idx == 4) return texture(samp5, uv);
    if (idx == 5) return texture(samp6, uv);
    if (idx == 6) return texture(samp7, uv);
    return texture(samp8, uv);
}

void main(void) {
    vec4 current = texture(samp, tc);

    float bass   = texture(spectrum, 0.05).r;
    float mid    = texture(spectrum, 0.25).r;
    float treble = texture(spectrum, 0.65).r;

    // Direction: radial from center, twisted by treble
    vec2 center = tc - 0.5;
    float dist = length(center);
    float angle = atan(center.y, center.x) + treble * 1.5;
    vec2 smearDir = vec2(cos(angle), sin(angle));

    // Smear length pulsed by bass
    float stepSize = 0.004 + bass * 0.012;

    // Chromatic accumulation across cache
    vec3 accumR = vec3(0.0);
    vec3 accumG = vec3(0.0);
    vec3 accumB = vec3(0.0);
    float totalW = 0.0;

    for (int i = 0; i < 8; i++) {
        float age = float(i + 1);
        float w = 1.0 / (1.0 + age * 0.4);

        vec2 offset = smearDir * stepSize * age;

        // Chromatic separation grows with distance and mid energy
        float chromaShift = mid * 0.003 * age;
        vec2 rOff = offset + vec2(chromaShift, 0.0);
        vec2 bOff = offset - vec2(chromaShift, 0.0);

        vec4 cR = sampleCache(i, tc + rOff);
        vec4 cG = sampleCache(i, tc + offset);
        vec4 cB = sampleCache(i, tc + bOff);

        accumR += vec3(cR.r, 0.0, 0.0) * w;
        accumG += vec3(0.0, cG.g, 0.0) * w;
        accumB += vec3(0.0, 0.0, cB.b) * w;
        totalW += w;
    }

    vec3 trail = (accumR + accumG + accumB) / max(totalW, 0.001);

    // Warm/cool shift based on bass vs treble dominance
    float warmth = bass / max(bass + treble, 0.01);
    trail *= mix(vec3(0.7, 0.85, 1.1), vec3(1.1, 0.9, 0.7), warmth);

    // Beat pulse: sudden brightness on bass transients
    float pulse = smoothstep(0.4, 0.8, bass) * 0.3;

    vec3 result = mix(current.rgb, max(current.rgb, trail), 0.5 + pulse);
    result *= 1.0 + pulse;

    color = vec4(result, 1.0);
}
