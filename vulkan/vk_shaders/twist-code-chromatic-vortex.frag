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



vec2 vortexUV(vec2 tc0, float turn, float radialShift) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc0 - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float wave = sin(r * 46.0 - time_f * 10.0 + a * 5.0);
    a += time_f * 1.1 + turn / r + wave * 0.28;
    r += radialShift + wave * 0.04;
    return fract(vec2(cos(a), sin(a)) * r / ar + 0.5);
}

void main(void) {
    vec2 ur = vortexUV(tc, 1.22, 0.012);
    vec2 ug = vortexUV(tc, 1.05, 0.0);
    vec2 ub = vortexUV(tc, 0.88, -0.012);
    vec3 rgb = vec3(texture(samp, ur).r,
                    texture(samp, ug).g,
                    texture(samp, ub).b);
    float r = length(tc - 0.5);
    rgb *= 0.85 + 0.35 * sin(r * 70.0 - time_f * 9.0);
    color = vec4(rgb, texture(samp, ug).a);
}
