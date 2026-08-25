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










const float TAU = 6.28318530718;

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float step_ = TAU / segments;
    ang = mod(ang, step_);
    ang = abs(ang - step_ * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + c;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);

    float stripe = sin(tc.y * 30.0 + t * 3.0);
    stripe = step(0.0, stripe);
    vec2 uv1 = tc;
    vec2 uv2 = vec2(1.0 - tc.x, tc.y);

    float seg = 6.0 + 4.0 * aLow;
    uv1 = reflectUV(uv1, seg, ctr, aspect);
    uv2 = reflectUV(uv2, seg + 2.0, ctr, aspect);

    uv1 = rotateUV(uv1, t * 0.15 + aMid * 0.3, ctr, aspect);
    uv2 = rotateUV(uv2, -t * 0.12 + aHigh * 0.3, ctr, aspect);

    vec4 c1 = texture(samp, fract(uv1));
    vec4 c2 = texture(samp, fract(uv2));
    vec4 tex = mix(c1, c2, stripe);

    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.1, 1.0, 1.2), clamp(amp_rms, 0.0, 1.0) * 0.5);
    color = tex;
}
