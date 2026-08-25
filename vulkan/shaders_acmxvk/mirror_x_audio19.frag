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
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = tc;
    if (uv.x < 0.5) uv.x = 1.0 - uv.x;
    float stretch = 1.0 + pingPong(t, 2.0) * 0.5 + 0.3 * aLow;
    uv.x = 0.5 + (uv.x - 0.5) * stretch;
    vec2 center = vec2(0.5) * iResolution;
    vec2 texCoord = uv * iResolution;
    vec2 delta = texCoord - center;
    float dist = length(delta);
    float maxR = min(iResolution.x, iResolution.y) * 0.5;
    if (dist < maxR) {
        float factor = pingPong(t + aMid * 2.0, 8.0) * (1.0 - pow(dist / maxR, 2.0));
        texCoord += normalize(delta) * factor * (30.0 + 40.0 * aHigh);
    }
    uv = texCoord / iResolution;
    vec4 tex = texture(samp, fract(uv));
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
