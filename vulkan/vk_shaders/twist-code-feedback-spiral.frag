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



vec2 rotate2(vec2 p, float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c) * p;
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.001;
    float baseTwist = time_f * 0.75 + 1.05 / r;
    vec3 sum = vec3(0.0);
    float weight = 0.0;
    for (int i = 0; i < 6; ++i) {
        float fi = float(i);
        float w = 1.0 - fi * 0.12;
        vec2 q = rotate2(p * (1.0 + fi * 0.085), baseTwist + fi * 0.42);
        q += normalize(q + vec2(0.0001)) * sin(r * (42.0 + fi * 8.0) - time_f * (8.0 + fi)) * 0.035;
        vec3 tap = texture(samp, fract(q / ar + 0.5)).rgb;
        sum += mix(tap, tap.bgr, fi / 10.0) * w;
        weight += w;
    }
    vec3 rgb = sum / weight;
    rgb *= 0.78 + 0.42 * sin(r * 64.0 - time_f * 11.0);
    color = vec4(rgb, texture(samp, tc).a);
}
