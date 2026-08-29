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
    vec2 uv = tc;
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    if (uv.x < 0.5) uv.x = 1.0 - uv.x;
    float chromaOff = 0.005 + 0.015 * aHigh;
    vec3 col;
    col.r = texture(samp, uv + vec2(chromaOff, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(chromaOff, 0.0)).b;
    float scanline = 0.95 + 0.05 * sin(tc.y * iResolution.y * 3.14159);
    col *= scanline;
    col *= 1.0 + amp_peak * 0.5;
    col = mix(col, col * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.2), amp_smooth);
    color = vec4(col, 1.0);
}
