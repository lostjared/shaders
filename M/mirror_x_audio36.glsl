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

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    vec2 p = uv - 0.5;
    float r = length(p);
    float a = atan(p.y, p.x);
    float segs = 6.0;
    float step_ = 6.28318 / segs;
    a = mod(a, step_);
    a = abs(a - step_ * 0.5);
    vec2 kp = vec2(cos(a), sin(a)) * r;
    kp = abs(kp) - 0.2 * (1.0 + aLow * 0.5);
    kp = rot(t * 0.3 + aMid * 0.5) * kp;
    kp = abs(kp) - 0.1;
    kp = rot(t * 0.2) * kp;
    uv = mirror(kp + 0.5);
    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    float glow = exp(-length(kp) * 5.0) * aHigh * 0.4;
    tex.rgb += glow * vec3(0.4, 1.0, 0.6);
    color = tex;
}
