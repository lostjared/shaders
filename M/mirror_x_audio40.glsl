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

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float segs = 8.0 + 4.0 * aLow;
    float step_ = 6.28318 / segs;
    a = mod(a, step_);
    a = abs(a - step_ * 0.5);
    vec2 kp = vec2(cos(a), sin(a)) * r;
    kp = rot(t * 0.3) * kp;
    kp = abs(kp) - 0.15 * (1.0 + aMid * 0.5);
    kp = rot(t * 0.2 + aHigh) * kp;
    kp = abs(kp);
    kp.x /= aspect;
    kp += 0.5;
    vec2 fuv = mirror(kp);
    vec4 tex = texture(samp, fuv);
    float hue = fract(r * 2.0 + a / 6.28318 + t * 0.1);
    vec3 rainbow = hsv2rgb(vec3(hue, 0.6, 1.0));
    float overlay = 0.2 + 0.3 * aMid;
    tex.rgb = mix(tex.rgb, tex.rgb * rainbow, overlay);
    tex.rgb *= 1.0 + amp_peak * 0.6;
    float vign = 1.0 - smoothstep(0.3, 0.9, r);
    tex.rgb *= 0.7 + 0.5 * vign;
    float bloom = pow(max(dot(tex.rgb, vec3(0.3, 0.6, 0.1)) - 0.5, 0.0), 2.0) * 0.2;
    tex.rgb += bloom;
    color = tex;
}
