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
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

vec2 sineFold(vec2 uv, float t, float strength, int iters) {
    vec2 p = uv;
    for (int i = 0; i < iters; i++) {
        float fi = float(i);
        p.x += strength * sin(p.y * (6.0 + fi * 2.3) + t * (0.9 + fi * 0.4));
        p.y += strength * cos(p.x * (5.0 + fi * 1.7) + t * (1.1 + fi * 0.3));
        p = fract(p);
    }
    return p;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float pulse = 1.0 + 0.3 * aLow * sin(t * 3.5);
    uv = (uv - 0.5) * pulse + 0.5;

    float strength = 0.03 + 0.05 * aMid;
    int iters = 4 + int(aPk * 4.0);
    uv = sineFold(uv, t, strength, iters);
    uv = mirror(uv);

    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.2, 0.95, 1.1 + aHigh * 0.2), aPk);
    color = tex;
}
