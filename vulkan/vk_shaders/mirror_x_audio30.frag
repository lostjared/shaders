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
    vec2 uv = tc;
    float hMirror = step(0.5, uv.x);
    uv.x = mix(1.0 - uv.x, uv.x, hMirror);
    float vMirror = step(0.5, uv.y);
    uv.y = mix(1.0 - uv.y, uv.y, vMirror);
    float glitch = floor(uv.y * (10.0 + 20.0 * aHigh));
    float offset = sin(glitch * 43.758 + t * 5.0) * 0.03 * aMid;
    uv.x += offset;
    uv.y += sin(t * 7.0 + uv.x * 15.0) * 0.005 * aLow;
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
