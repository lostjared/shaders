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
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;









void main(void) {
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aRms  = clamp(amp_rms,  0.0, 1.0);

    vec2 uv = tc;
    float amplitude = aRms * 0.8 + 0.1;
    float freq = 10.0 + aLow * 15.0;
    float speed = 1.0 + aHigh * 3.0;
    vec2 distortedUV = uv + vec2(
        sin(uv.y * freq + time_f * speed) * 0.1,
        cos(uv.x * freq + time_f * speed) * 0.1
    ) * amplitude;
    color = texture(samp, distortedUV);
}
