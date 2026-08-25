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



void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float w0 = sin(r * 34.0 - time_f * 7.0);
    float w1 = sin(r * 71.0 + a * 7.0 - time_f * 13.0);
    float w2 = cos(r * 143.0 - a * 11.0 + time_f * 19.0);
    float wave = w0 * 0.06 + w1 * 0.035 + w2 * 0.017;
    a += 1.0 / r + time_f * 1.15 + w1 * 0.22;
    r += wave;
    vec2 uv = fract(vec2(cos(a), sin(a)) * r / ar + 0.5);
    vec2 kick = vec2(cos(a), sin(a)) / ar * wave;
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, fract(uv + kick * 1.8));
    vec3 rgb = mix(c0.rgb, c1.rgb, 0.52);
    rgb *= 0.68 + 0.22 * w0 + 0.22 * w1 + 0.18 * w2 + 0.55;
    color = vec4(rgb, c0.a);
}
