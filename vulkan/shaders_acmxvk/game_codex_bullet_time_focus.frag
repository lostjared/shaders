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

// Bullet time focus: sharp center with radial peripheral blur.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    vec2 dir = normalize(p + 1e-5);
    float amount = smoothstep(0.05, 0.36, dot(p, p));
    vec3 acc = vec3(0.0);
    float total = 0.0;
    for (int i = -3; i <= 3; ++i) {
        float f = float(i);
        float w = exp(-f * f * 0.35);
        acc += texture(samp, clamp(tc + dir * f * 0.01 * amount, 0.0, 1.0)).rgb * w;
        total += w;
    }
    vec3 c = acc / total;
    c = mix(c, vec3(dot(c, vec3(0.299, 0.587, 0.114))), amount * 0.25);
    color = vec4(c, 1.0);
}
