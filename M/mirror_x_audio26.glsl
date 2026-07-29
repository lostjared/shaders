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
    vec2 uv = tc;
    if (uv.x < 0.5) uv.x = 1.0 - uv.x;
    if (uv.y < 0.5) uv.y = 1.0 - uv.y;
    vec2 p = uv - 0.75;
    float r = length(p);
    float a = atan(p.y, p.x);
    float wobble = sin(a * (3.0 + 2.0 * aLow) + t * 2.0) * 0.05 * aMid;
    r += wobble;
    float squeeze = 1.0 + 0.3 * sin(t * 1.5) * aHigh;
    p = vec2(cos(a), sin(a)) * r * vec2(squeeze, 1.0);
    uv = p + 0.75;
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
