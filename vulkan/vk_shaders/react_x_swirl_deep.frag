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

    vec2 center = vec2(0.5);
    vec2 uv = tc - center;
    float dist = length(uv);
    float angle = time_f * (1.0 + aSmth * 3.0) + dist * (5.0 + aLow * 15.0);
    float s = sin(angle), c = cos(angle);

    uv = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);

    float zoom = 1.0 + aMid * 0.3;
    uv *= zoom;
    uv += center;

    color = texture(samp, uv);
}
