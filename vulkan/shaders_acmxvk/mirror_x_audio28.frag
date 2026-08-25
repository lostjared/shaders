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









void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float dist = length(uv - 0.5);
    float fishEye = 1.0 + (1.0 + aLow) * pow(dist, 2.0);
    uv = (uv - 0.5) / fishEye + 0.5;
    uv.x += sin(t * 2.0 + uv.y * 8.0) * 0.015 * aMid;
    uv.y += cos(t * 1.7 + uv.x * 8.0) * 0.015 * aHigh;
    uv = fract(uv);
    vec3 col;
    float off = 0.004 * amp_smooth;
    col.r = texture(samp, uv + vec2(off, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(off, 0.0)).b;
    col *= 1.0 + amp_peak * 0.5;
    color = vec4(col, 1.0);
}
