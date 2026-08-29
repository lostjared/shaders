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
    float aHigh = clamp(amp_high, 0.0, 1.0);
    vec2 uv = tc;
    if (uv.x > 0.5) uv.x = 1.0 - uv.x;
    if (uv.y > 0.5) uv.y = 1.0 - uv.y;
    float t = time_f;
    float stretch = 1.0 + 0.5 * aLow * sin(t * 3.0);
    uv = (uv - 0.25) * stretch + 0.25;
    uv = clamp(uv, 0.0, 1.0);
    vec3 col;
    float off = 0.003 + 0.01 * aHigh;
    col.r = texture(samp, uv + vec2(off, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(off, 0.0)).b;
    col *= 1.0 + amp_peak * 0.5;
    color = vec4(col, 1.0);
}
