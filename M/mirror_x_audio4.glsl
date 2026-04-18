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
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    a += sin(r * 10.0 - time_f * 2.0) * 0.5 * aLow;
    r += cos(a * 4.0 + time_f) * 0.05 * aHigh;
    vec2 warped = vec2(cos(a), sin(a)) * r;
    warped.x /= aspect;
    warped += 0.5;
    vec4 tex = texture(samp, fract(warped));
    tex.rgb *= 1.0 + amp_peak * 0.6;
    color = tex;
}
