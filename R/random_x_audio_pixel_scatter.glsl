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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main(void) {
    // Peak-driven pixel scatter intensity
    float scatterAmt = amp_peak * 0.08 + amp_rms * 0.02;

    // Block size from mids
    float blockSize = 16.0 + amp_mid * 48.0;
    vec2 block = floor(tc * iResolution / blockSize);

    // Each block gets a random displacement on peaks
    float h1 = hash(block + floor(time_f * 6.0));
    float h2 = hash(block.yx + floor(time_f * 6.0) + 37.0);

    vec2 offset = vec2(0.0);
    if (h1 < amp_peak * 0.4) {
        offset.x = (h1 - 0.5) * scatterAmt * 2.0;
        offset.y = (h2 - 0.5) * scatterAmt * 2.0;
    }

    vec2 uv = tc + offset;

    // Bass adds a global wave scatter
    uv.x += amp_low * 0.015 * sin(tc.y * 30.0 + time_f * 4.0);
    uv.y += amp_low * 0.01 * cos(tc.x * 25.0 + time_f * 3.0);

    vec4 tex = texture(samp, clamp(uv, 0.0, 1.0));

    // Treble noise overlay
    float noise = hash(tc * iResolution + time_f) * amp_high * 0.15;
    tex.rgb += noise;

    // Smooth brightness
    tex.rgb *= 1.0 + amp_smooth * 0.2;

    // Peak brightness flash
    tex.rgb += smoothstep(0.7, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
