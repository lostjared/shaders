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










vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 c, float aspect, int iters) {
    vec2 p = uv;
    for (int i = 0; i < iters; i++) {
        p = abs((p - c) * (zoom + 0.15 * sin(t * 0.35 + float(i)))) - 0.5 + c;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
    }
    return p;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);

    float glitch = floor(uv.y * (10.0 + 20.0 * aHigh));
    float offset = sin(glitch * 43.758 + t * 5.0) * 0.04 * aMid;
    uv.x += offset;

    float zoom = 1.3 + 0.5 * sin(t * 0.4) + 0.4 * aLow;
    uv = fractalFold(uv, zoom, t, ctr, aspect, 5 + int(aPk * 3.0));
    uv = fract(uv);

    float glitch2 = floor(uv.y * (15.0 + 10.0 * aHigh));
    float offset2 = sin(glitch2 * 17.31 + t * 8.0) * 0.02 * aPk;
    uv.x += offset2;
    uv = fract(uv);

    vec4 tex = texture(samp, uv);
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.1 + aLow * 0.2, 0.9, 1.0 + aHigh * 0.3), aPk);
    color = tex;
}
