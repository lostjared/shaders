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
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    vec2 grid = vec2(8.0, 6.0);
    vec2 id = floor(tc * grid), cell = fract(tc * grid) - 0.5;
    vec2 jitter = vec2(hash21(id), hash21(id + 17.3)) - 0.5;
    vec2 d = cell - jitter * 0.45;
    float radius = 0.18 + hash21(id + 5.2) * 0.17;
    float r = length(d);
    float mask = 1.0 - smoothstep(radius - 0.035, radius, r);
    float breathe = 0.88 + 0.12 * sin(time_f * 0.8 + hash21(id) * 6.283);
    vec2 lens = d * (1.0 - breathe * 0.20 * mask) / grid;
    vec2 base = (id + 0.5 + jitter * 0.45) / grid;
    vec2 uv = safeUV(mix(tc, base + lens, mask));
    vec4 src = texture(samp, uv);
    float rim = smoothstep(radius - 0.055, radius - 0.018, r) *
                (1.0 - smoothstep(radius - 0.018, radius, r));
    color = vec4(src.rgb + vec3(0.18, 0.25, 0.27) * rim, texture(samp, tc).a);
}
