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
    float y = tc.y * iResolution.y;

    // Peak drives horizontal tear intensity
    float tearStrength = amp_peak * 0.1;
    float tearFreq = 8.0 + amp_low * 20.0;

    // Random horizontal bands that tear on peaks
    float bandIndex = floor(y / tearFreq);
    float bandHash = hash(bandIndex + floor(time_f * 4.0));

    if (bandHash < amp_peak * 0.6) {
        // Tear this band
        float tearOffset = (bandHash - 0.3) * tearStrength;
        uv.x += tearOffset;

        // Bass makes some bands jump vertically
        if (bandHash < amp_low * 0.3) {
            float jumpHash = hash(bandIndex * 13.0 + time_f);
            uv.y += (jumpHash - 0.5) * amp_low * 0.04;
        }
    }

    // Mids add subtle wave across all lines
    uv.x += amp_mid * 0.005 * sin(y * 0.1 + time_f * 3.0);

    uv = clamp(uv, 0.0, 1.0);

    // Treble chromatic tear
    float chromaTear = amp_high * 0.01 * step(bandHash, amp_peak * 0.4);
    float r = texture(samp, clamp(vec2(uv.x + chromaTear, uv.y), 0.0, 1.0)).r;
    float g = texture(samp, uv).g;
    float b = texture(samp, clamp(vec2(uv.x - chromaTear, uv.y), 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Scanline darken
    float scanline = 0.97 + 0.03 * sin(y * 3.14159);
    col *= scanline;

    // RMS brightness
    col *= 1.0 + amp_rms * 0.2;

    // Peak flash
    col += smoothstep(0.7, 1.0, amp_peak) * 0.15;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
