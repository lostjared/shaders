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
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    float dist = length(uv - 0.5);
    float bulge = 1.0 + 0.4 * aLow * smoothstep(0.5, 0.0, dist);
    uv = (uv - 0.5) * bulge + 0.5;
    uv.x += sin(uv.y * 15.0 + t * 3.0) * 0.02 * aMid;
    uv.y += cos(uv.x * 15.0 + t * 2.5) * 0.02 * aHigh;
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    float vign = 1.0 - smoothstep(0.3, 0.8, dist);
    tex.rgb *= 0.8 + 0.4 * vign;
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
