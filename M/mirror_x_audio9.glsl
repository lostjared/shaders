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

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float segs = 8.0;
    float step_ = 6.28318 / segs;
    a = mod(a, step_);
    a = abs(a - step_ * 0.5);
    vec2 kp = vec2(cos(a), sin(a)) * r;
    float rotAmt = time_f * 0.5 + aLow * 1.5;
    kp = rot(rotAmt) * kp;
    kp.x /= aspect;
    kp += 0.5;
    float zoom = 1.0 + 0.2 * aMid;
    kp = (kp - 0.5) * zoom + 0.5;
    vec4 tex = texture(samp, fract(kp));
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
