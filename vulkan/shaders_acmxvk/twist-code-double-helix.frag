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
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



vec2 whirl(vec2 uv, vec2 center, float direction) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (uv - center) * ar;
    float r = length(p) + 0.025;
    float a = atan(p.y, p.x);
    a += direction * (1.0 / r + time_f * 1.25);
    r += sin(r * 48.0 - time_f * 9.0 + direction * a * 6.0) * 0.045;
    return vec2(cos(a), sin(a)) * r / ar + center;
}

void main(void) {
    vec2 orbit = vec2(cos(time_f * 0.7), sin(time_f * 0.7)) * 0.17;
    vec2 u0 = whirl(tc, vec2(0.5) + orbit, 1.0);
    vec2 u1 = whirl(tc, vec2(0.5) - orbit, -1.0);
    vec2 uv = fract(mix(u0, u1, 0.5 + 0.5 * sin((tc.x + tc.y) * 35.0 - time_f * 6.0)));
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, fract(mix(u1, u0, 0.36)));
    float braid = 0.5 + 0.5 * sin((tc.x - tc.y) * 50.0 + time_f * 8.0);
    color = vec4(mix(c0.rgb, c1.bgr, braid * 0.42), c0.a);
}
