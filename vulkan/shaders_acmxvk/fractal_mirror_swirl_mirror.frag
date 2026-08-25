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










vec2 rotate2D(vec2 p, float angle) {
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c) * p;
}

vec2 swirl(vec2 uv, vec2 center, float radius, float strength) {
    float dist = distance(uv, center);
    if (dist < radius) {
        float percent = (radius - dist) / radius;
        float theta = percent * percent * strength;
        uv = rotate2D(uv - center, theta) + center;
    }
    return uv;
}

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 c, int iters) {
    vec2 p = uv;
    for (int i = 0; i < iters; i++) {
        p = abs((p - c) * (zoom + 0.15 * sin(t * 0.35 + float(i)))) - 0.5 + c;
        p = rotate2D(p - c, t * 0.12 + float(i) * 0.07) + c;
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
    float swirlStr = sin(t * 0.6) * 4.0 * (1.0 + aMid * 2.0);
    uv = swirl(uv, vec2(0.5), 0.7 + 0.2 * aLow, swirlStr);

    float zoom = 1.3 + 0.4 * aLow;
    uv = fractalFold(uv, zoom, t, vec2(0.5), 4);
    uv = 1.0 - abs(1.0 - 2.0 * fract(uv));

    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.3), aPk);
    color = tex;
}
