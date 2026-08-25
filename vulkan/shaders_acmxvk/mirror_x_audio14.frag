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
    float t = time_f;
    vec2 uv = tc;
    float split = 0.5 + 0.2 * sin(t * 0.5) * aLow;
    if (uv.x < split) {
        uv.x = split - uv.x;
    } else {
        uv.x = uv.x - split;
    }
    uv.x = uv.x / (1.0 - split + 0.001);
    float wave = sin(uv.y * 20.0 + t * 3.0) * 0.02 * aHigh;
    uv.x += wave;
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + amp_peak * 0.4;
    color = tex;
}
