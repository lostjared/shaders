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
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float dist = length(uv - 0.5);
    float fishEye = 1.0 + (1.0 + aLow) * pow(dist, 2.0);
    uv = (uv - 0.5) / fishEye + 0.5;
    uv.x += sin(t * 2.0 + uv.y * 8.0) * 0.015 * aMid;
    uv.y += cos(t * 1.7 + uv.x * 8.0) * 0.015 * aHigh;
    uv = fract(uv);
    vec3 col;
    float off = 0.004 * amp_smooth;
    col.r = texture(samp, uv + vec2(off, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(off, 0.0)).b;
    col *= 1.0 + amp_peak * 0.5;
    color = vec4(col, 1.0);
}
