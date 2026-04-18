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
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float segments = 12.0;
    float step_ = 6.28318 / segments;
    a = mod(a, step_);
    a = abs(a - step_ * 0.5);
    vec2 kp = vec2(cos(a), sin(a)) * r;
    kp.x /= aspect;
    kp += 0.5;
    float breathe = 1.0 + 0.15 * sin(t * 1.5) * aLow;
    kp = (kp - 0.5) * breathe + 0.5;
    kp = mirror(kp);
    vec4 tex = texture(samp, kp);
    float vign = 1.0 - smoothstep(0.3, 0.8, r);
    tex.rgb *= 0.7 + 0.5 * vign;
    tex.rgb *= 1.0 + amp_peak * 0.5;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aMid * 0.2, 1.0, 1.0 + aHigh * 0.3), 0.5);
    color = tex;
}
