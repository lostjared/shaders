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
    vec2 uv = tc;

    // Bass drives sine fold amplitude
    float foldStrength = 0.01 + amp_low * 0.06;
    int iters = 2 + int(amp_rms * 4.0);

    for (int i = 0; i < 6; i++) {
        if (i >= iters) break;
        float fi = float(i);
        float freq = 6.0 + fi * 2.3 + amp_mid * 4.0;
        float speed = 0.9 + fi * 0.4 + amp_mid * 1.0;
        uv.x += foldStrength * sin(uv.y * freq + time_f * speed);
        uv.y += foldStrength * cos(uv.x * (5.0 + fi * 1.7) + time_f * (1.1 + fi * 0.3));
    }

    uv = abs(mod(uv, 2.0) - 1.0);

    // Treble chromatic split along fold
    float chroma = amp_high * 0.02;
    float r = texture(samp, clamp(uv + vec2(chroma, 0.0), 0.0, 1.0)).r;
    float g = texture(samp, clamp(uv, 0.0, 1.0)).g;
    float b = texture(samp, clamp(uv - vec2(chroma, 0.0), 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Smooth brightness
    col *= 1.0 + amp_smooth * 0.25;

    // Peak flash
    col += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
