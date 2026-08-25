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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




vec2 mirrorWrap(vec2 p) {
    return abs(fract(p) * 2.0 - 1.0);
}

void main(void) {
    float t = time_f * 0.45;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= iResolution.x / max(iResolution.y, 1.0);
    p -= mouseP * 0.08;
    float r = length(p);
    float a = atan(p.y, p.x);
    float lens = 1.0 / max(0.18, r + 0.08 * sin(a * 5.0 + t));
    vec2 q = vec2(a / 6.283185 + 0.5 + t * 0.05, fract(lens * 0.23 - t * 0.08));
    vec3 acc = vec3(0.0);
    acc += texture(samp, mirrorWrap(q)).rgb * 0.50;
    acc += texture(samp, mirrorWrap(q + vec2(0.033, 0.061))).rgb * 0.25;
    acc += texture(samp, mirrorWrap(q - vec2(0.071, 0.027))).rgb * 0.25;
    acc += texture(samp, mirrorWrap(q + (mouseP - p) * 0.04)).rgb * smoothstep(1.25, 0.0, length(p - mouseP)) * 0.18;
    float rings = smoothstep(0.96, 1.0, sin(lens * 10.0 + t * 4.0) * 0.5 + 0.5);
    vec3 tint = 0.55 + 0.45 * cos(vec3(0.4, 2.5, 4.6) + a * 2.0 - t);
    color = vec4(acc * (0.82 + rings * 0.55) + tint * rings * 0.25, 1.0);
}
