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
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    vec2 uv = tc;
    if (uv.x > 0.5) uv.x = 1.0 - uv.x;
    if (uv.y > 0.5) uv.y = 1.0 - uv.y;
    float t = time_f;
    float stretch = 1.0 + 0.5 * aLow * sin(t * 3.0);
    uv = (uv - 0.25) * stretch + 0.25;
    uv = clamp(uv, 0.0, 1.0);
    vec3 col;
    float off = 0.003 + 0.01 * aHigh;
    col.r = texture(samp, uv + vec2(off, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(off, 0.0)).b;
    col *= 1.0 + amp_peak * 0.5;
    color = vec4(col, 1.0);
}
