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

float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : len * 2.0 - m;
}

void main(void) {
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float t = time_f;
    float segments = 6.0 + 4.0 * aLow;
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float step_ = 6.28318 / segments;
    ang = mod(ang, step_);
    ang = abs(ang - step_ * 0.5);
    vec2 reflected = vec2(cos(ang), sin(ang)) * rad;
    reflected.x /= aspect;
    reflected += 0.5;
    float zoom = 1.0 + 0.3 * pingPong(t * 0.5, 2.0) + 0.2 * aMid;
    reflected = (reflected - 0.5) * zoom + 0.5;
    vec4 tex = texture(samp, fract(reflected));
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
