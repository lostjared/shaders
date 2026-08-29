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



vec2 orbitWarp(vec2 uv, vec2 c, float direction) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (uv - c) * ar;
    float r = length(p) + 0.018;
    float a = atan(p.y, p.x) + direction * (0.55 / r + time_f * 0.9);
    r += sin(r * 55.0 - time_f * 10.0 + direction * a * 8.0) * 0.036;
    return vec2(cos(a), sin(a)) * r / ar + c;
}

void main(void) {
    float t = time_f * 0.62;
    vec2 c0 = vec2(0.5) + vec2(cos(t), sin(t)) * 0.23;
    vec2 c1 = vec2(0.5) + vec2(cos(t + 2.094), sin(t + 2.094)) * 0.23;
    vec2 c2 = vec2(0.5) + vec2(cos(t + 4.189), sin(t + 4.189)) * 0.23;
    vec2 uv = orbitWarp(tc, c0, 1.0);
    uv = orbitWarp(uv, c1, -1.0);
    uv = fract(orbitWarp(uv, c2, 1.0));
    vec4 tex = texture(samp, uv);
    vec3 echo = texture(samp, fract(uv.yx + vec2(0.07, -0.04))).bgr;
    color = vec4(mix(tex.rgb, echo, 0.28), tex.a);
}
