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

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float segs = 8.0;
    float step_ = 6.28318 / segs;
    float a = atan(p.y, p.x);
    float r = length(p);
    a = mod(a, step_);
    a = abs(a - step_ * 0.5);
    vec2 kp = vec2(cos(a), sin(a)) * r;
    kp = rot(t * 0.4 + aLow) * kp;
    float zoom = 1.5 + 0.5 * sin(t * 0.3) + 0.3 * aMid;
    kp *= zoom;
    kp = abs(kp);
    kp -= 0.3;
    kp = rot(t * 0.2 + aHigh * 0.5) * kp;
    kp = abs(kp);
    kp.x /= aspect;
    kp += 0.5;
    vec4 tex = texture(samp, mirror(kp));
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
