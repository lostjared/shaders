#version 330 core
// Temporal Prism — Splits each cache frame into its own color channel
// and offset direction. Moving objects leave R/G/B separated trails
// that converge and diverge over time, like light through a prism.

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

    // Three prism directions, 120 degrees apart, rotating over time
    float baseAngle = time_f * 0.6;
    vec2 dirR = vec2(cos(baseAngle), sin(baseAngle));
    vec2 dirG = vec2(cos(baseAngle + 2.094), sin(baseAngle + 2.094));
    vec2 dirB = vec2(cos(baseAngle + 4.189), sin(baseAngle + 4.189));

    // Spread amount oscillates
    float spread = 0.005 + 0.003 * sin(time_f * 0.9);

    // Accumulate each channel separately across the 8 cache frames
    float rAccum = current.r;
    float gAccum = current.g;
    float bAccum = current.b;
    float rW = 1.0, gW = 1.0, bW = 1.0;

    for (int i = 0; i < 8; i++) {
        float age = float(i + 1);
        float w = 1.0 / (1.0 + age * 0.4);
        float offset = spread * age;

        // R channel trails in dirR direction
        vec4 cR = sampleCache(i, tc + dirR * offset);
        rAccum += cR.r * w;
        rW += w;

        // G channel trails in dirG direction
        vec4 cG = sampleCache(i, tc + dirG * offset);
        gAccum += cG.g * w;
        gW += w;

        // B channel trails in dirB direction
        vec4 cB = sampleCache(i, tc + dirB * offset);
        bAccum += cB.b * w;
        bW += w;
    }

    vec3 result = vec3(rAccum / rW, gAccum / gW, bAccum / bW);

    // Subtle vignette to frame the prism effect
    float dist = length(tc - 0.5) * 1.4;
    result *= 1.0 - dist * dist * 0.3;

    color = vec4(result, 1.0);
}
