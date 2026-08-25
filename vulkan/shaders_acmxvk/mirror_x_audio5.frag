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
