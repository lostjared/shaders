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

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float t = time_f;
    float swirl = 0.5 + 1.5 * aLow;
    vec2 p = uv - 0.5;
    float r = length(p);
    float a = atan(p.y, p.x);
    a += swirl * exp(-r * 3.0) * sin(t * 2.0);
    uv = vec2(cos(a), sin(a)) * r + 0.5;
    uv = mirror(uv);
    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    tex.rgb += aMid * 0.15 * vec3(sin(t), cos(t * 1.3), sin(t * 0.7));
    color = tex;
}
