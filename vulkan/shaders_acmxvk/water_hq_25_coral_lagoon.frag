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


vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
float lagoon(vec2 p) {
    float t = time_f * 0.48;
    float a = sin(p.x * 17.0 + sin(p.y * 9.0 - t) * 2.4 + t);
    float b = sin(p.y * 20.0 + sin(p.x * 8.0 + t) * 2.1 - t * 1.2);
    return a + b + 0.45 * sin((p.x - p.y) * 29.0 + t * 1.7);
}

void main(void) {
    float e = 0.002;
    float h = lagoon(tc);
    vec2 grad = vec2(lagoon(tc + vec2(e, 0)) - h, lagoon(tc + vec2(0, e)) - h) / e;
    vec4 src = texture(samp, safeUV(tc + grad * 0.00055));
    float caustic = pow(clamp(1.0 - abs(h) * 0.28, 0.0, 1.0), 6.0);
    float shallows = 1.0 - smoothstep(0.0, 1.0, tc.y);
    vec3 tint = mix(vec3(0.78, 0.96, 1.02), vec3(0.92, 1.02, 0.96), shallows);
    vec3 rgb = src.rgb * tint + vec3(0.08, 0.19, 0.16) * caustic * (0.20 + shallows * 0.16);
    color = vec4(rgb, texture(samp, tc).a);
}
