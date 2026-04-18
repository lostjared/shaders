#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

void main(void) {
    vec2 uv = tc;
    float y = uv.y * iResolution.y;

    // Peak-driven horizontal glitch tear
    float glitchStrength = amp_peak * 0.08;
    float lineHash = hash(floor(y * 0.1) + floor(time_f * 8.0));
    if (lineHash < amp_peak * 0.5) {
        uv.x += (hash(y + time_f) - 0.5) * glitchStrength;
    }

    // Bass causes block displacement
    float blockSize = 32.0 + amp_low * 64.0;
    vec2 block = floor(uv * iResolution / blockSize);
    float blockHash = hash(dot(block, vec2(17.0, 43.0)) + floor(time_f * 4.0));
    if (blockHash < amp_low * 0.3) {
        uv.x += (blockHash - 0.5) * 0.05;
    }

    // RGB split driven by treble
    float split = amp_high * 0.015 + amp_peak * 0.01;
    float r = texture(samp, clamp(vec2(uv.x + split, uv.y), 0.0, 1.0)).r;
    float g = texture(samp, clamp(uv, 0.0, 1.0)).g;
    float b = texture(samp, clamp(vec2(uv.x - split, uv.y), 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Mid-range adds scanline intensity
    float scanline = 0.95 + 0.05 * sin(y * 3.0 + time_f * amp_mid * 20.0);
    col *= scanline;

    // Peak flash
    col += smoothstep(0.7, 1.0, amp_peak) * 0.15;

    color = vec4(col, 1.0);
}
