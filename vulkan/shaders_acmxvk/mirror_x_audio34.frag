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
    float segs = 5.0;
    float step_ = 6.28318 / segs;
    a = mod(a, step_);
    a = abs(a - step_ * 0.5);
    float petals = 0.3 + 0.2 * sin(a * segs * 2.0 + t) * aLow;
    float newR = r * (1.0 + petals * aMid);
    vec2 kp = vec2(cos(a), sin(a)) * newR;
    kp.x /= aspect;
    kp += 0.5;
    kp = mirror(kp);
    vec4 tex = texture(samp, kp);
    float ring = abs(sin(r * 15.0 - t * 3.0));
    ring = smoothstep(0.8, 1.0, ring) * aHigh * 0.3;
    tex.rgb += ring * vec3(0.3, 0.7, 1.0);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
