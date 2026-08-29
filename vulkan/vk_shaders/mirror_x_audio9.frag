#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp ext.u1.y
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;









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
