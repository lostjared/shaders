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









vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float n = 3.0 + floor(aLow * 5.0);
    for (int i = 0; i < 5; i++) {
        if (float(i) >= n) break;
        uv = abs(uv * 2.0 - 1.0);
        uv *= 1.0 + 0.05 * sin(t + float(i) * 1.7) * aMid;
    }
    uv = mirror(uv);
    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    tex.rgb += aHigh * 0.1 * vec3(sin(t * 2.0), sin(t * 2.5), sin(t * 3.0)) * 0.5 + 0.5;
    color = tex;
}
