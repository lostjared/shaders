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

layout(set = 0, binding = 3) uniform sampler1D spectrum;

// Three layered twists from low/mid/high bands composed sequentially.
vec2 twistOnce(vec2 uv, float strength, float t) {
    vec2 center = vec2(0.5);
    vec2 d = uv - center;
    float r = length(d);
    float a = strength * (r - 1.0) + t;
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c) * d + center;
}

void main(void) {
    float lo = texture(spectrum, 0.05).r;
    float md = texture(spectrum, 0.30).r;
    float hi = texture(spectrum, 0.70).r;

    vec2 uv = tc;
    uv = twistOnce(uv, 1.0 + lo * 5.0, time_f * 0.5);
    uv = twistOnce(uv, 1.0 + md * 4.0, -time_f * 0.7);
    uv = twistOnce(uv, 1.0 + hi * 3.0, time_f * 1.1);

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, uv, 0.5));
}
