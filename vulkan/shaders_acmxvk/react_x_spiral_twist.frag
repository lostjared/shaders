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
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aSmth = clamp(amp_smooth, 0.0, 1.0);

    vec2 uv = tc - 0.5;
    float radius = length(uv);
    float angle = atan(uv.y, uv.x);

    float twist = 10.0 + aLow * 20.0;
    float speed = 0.5 + aSmth * 2.0;
    angle += radius * twist + time_f * speed;

    vec2 spiralUV = vec2(cos(angle), sin(angle)) * radius;
    float zoom = 1.0 - aMid * 0.2;
    color = texture(samp, spiralUV * zoom + 0.5);
}
