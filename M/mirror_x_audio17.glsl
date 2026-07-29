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
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    vec2 center = vec2(0.5);
    float dist = length(uv - center);
    float angle = t * 2.0 + dist * (5.0 + 5.0 * aLow);
    float s = sin(angle), c = cos(angle);
    uv = vec2(
        (uv.x - center.x) * c - (uv.y - center.y) * s,
        (uv.x - center.x) * s + (uv.y - center.y) * c
    ) + center;
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    float pulse = 0.5 + 0.5 * sin(t * 6.0) * aMid;
    tex.rgb = mix(tex.rgb, tex.rgb * 1.3, pulse);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
