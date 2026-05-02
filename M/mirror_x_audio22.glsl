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
    if (uv.x < 0.5)
        uv.x = 1.0 - uv.x;
    vec2 p = uv - 0.5;
    float r = length(p);
    float lens = 1.0 + (0.5 + 0.5 * aLow) * (1.0 - smoothstep(0.0, 0.4, r));
    uv = p * lens + 0.5;
    uv.x += sin(t * 3.0 + uv.y * 10.0) * 0.01 * aMid;
    uv.y += cos(t * 2.5 + uv.x * 10.0) * 0.01 * aHigh;
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
