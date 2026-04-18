#version 330 core
// Spectral Smear — Directional motion blur using cache frames
// The 8 history frames are sampled with progressive offset in a
// time-rotating direction, creating a smooth motion smear trail.

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

    // Smear direction rotates slowly over time
    float angle = time_f * 0.4;
    vec2 smearDir = vec2(cos(angle), sin(angle));

    // Smear length per step
    float stepSize = 0.008;

    // Accumulate smeared trail with chromatic separation
    vec3 trailR = vec3(0.0);
    vec3 trailG = vec3(0.0);
    vec3 trailB = vec3(0.0);
    float totalW = 0.0;

    for (int i = 0; i < 8; i++) {
        float age = float(i + 1);
        float w = 1.0 / (1.0 + age * 0.5);

        // Progressive offset along smear direction
        vec2 offset = smearDir * stepSize * age;

        // Chromatic separation: R/G/B get slightly different offsets
        float chromSplit = 0.002 * age;
        vec2 perpDir = vec2(-smearDir.y, smearDir.x);

        trailR += sampleCache(i, tc + offset + perpDir * chromSplit).rgb * w;
        trailG += sampleCache(i, tc + offset).rgb * w;
        trailB += sampleCache(i, tc + offset - perpDir * chromSplit).rgb * w;
        totalW += w;
    }

    trailR /= totalW;
    trailG /= totalW;
    trailB /= totalW;

    // Composite: take R from red trail, G from center trail, B from blue trail
    vec3 smeared = vec3(trailR.r, trailG.g, trailB.b);

    // Edge detection on current frame for sharp overlay
    vec2 px = 1.0 / iResolution;
    float lum = dot(current.rgb, vec3(0.299, 0.587, 0.114));
    float lumR = dot(texture(samp, tc + vec2(px.x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    float lumU = dot(texture(samp, tc + vec2(0.0, px.y)).rgb, vec3(0.299, 0.587, 0.114));
    float edge = abs(lum - lumR) + abs(lum - lumU);
    edge = smoothstep(0.02, 0.15, edge);

    // Current frame shows through strongly on edges, smear elsewhere
    vec3 result = mix(smeared, current.rgb, 0.3 + edge * 0.5);

    color = vec4(result, 1.0);
}
