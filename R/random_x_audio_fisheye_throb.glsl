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

void main(void) {
    vec2 center = vec2(0.5);
    vec2 delta = tc - center;
    float dist = length(delta * vec2(iResolution.x / iResolution.y, 1.0));

    // Bass pulses the fisheye lens intensity
    float lensStrength = 0.3 + amp_low * 0.8;
    float lensRadius = 0.8 + amp_smooth * 0.3;

    vec2 uv = tc;
    if (dist < lensRadius) {
        float normalDist = dist / lensRadius;
        float bend = normalDist * normalDist * lensStrength;
        uv = center + delta * (1.0 + bend);
    }

    // Mids add a secondary wobble
    uv.x += amp_mid * 0.01 * sin(uv.y * 20.0 + time_f * 3.0);
    uv.y += amp_mid * 0.008 * cos(uv.x * 15.0 + time_f * 2.5);

    uv = clamp(uv, 0.0, 1.0);

    // Treble chromatic split
    float chroma = amp_high * 0.015;
    float r = texture(samp, clamp(uv + vec2(chroma, 0.0), 0.0, 1.0)).r;
    float g = texture(samp, uv).g;
    float b = texture(samp, clamp(uv - vec2(chroma, 0.0), 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Peak breathing flash
    col *= 1.0 + smoothstep(0.5, 1.0, amp_peak) * 0.35;

    // RMS warmth
    col.r += amp_rms * 0.04;
    col.g += amp_rms * 0.02;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
