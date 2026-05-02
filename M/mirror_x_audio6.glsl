#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float amp_peak;
uniform float amp_smooth;

void main(void) {
    vec2 uv = tc;
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    if (uv.x < 0.5)
        uv.x = 1.0 - uv.x;
    float chromaOff = 0.005 + 0.015 * aHigh;
    vec3 col;
    col.r = texture(samp, uv + vec2(chromaOff, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(chromaOff, 0.0)).b;
    float scanline = 0.95 + 0.05 * sin(tc.y * iResolution.y * 3.14159);
    col *= scanline;
    col *= 1.0 + amp_peak * 0.5;
    col = mix(col, col * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.2), amp_smooth);
    color = vec4(col, 1.0);
}
