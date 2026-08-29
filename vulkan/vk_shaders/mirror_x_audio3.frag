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
    float aMid = clamp(amp_mid, 0.0, 1.0);
    if (uv.x < 0.5) uv.x = 1.0 - uv.x;
    if (uv.y < 0.5) uv.y = 1.0 - uv.y;
    float dist = length(uv - 0.5);
    float wave = sin(dist * 20.0 - time_f * 3.0) * 0.02 * aLow;
    uv += wave;
    vec4 tex = texture(samp, uv);
    float glow = smoothstep(0.4, 0.0, dist) * aMid * 0.5;
    tex.rgb += glow * vec3(0.3, 0.6, 1.0);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
