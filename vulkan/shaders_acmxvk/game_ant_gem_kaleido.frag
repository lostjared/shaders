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

// Gem kaleido edges — kaleidoscope reflection ONLY at extreme edges.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



vec2 kaleido(vec2 uv, float seg) {
    vec2 p = uv - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float a = atan(p.y, p.x);
    float r = length(p);
    float st = 6.28318 / seg;
    a = mod(a, st); a = abs(a - st * 0.5);
    p = vec2(cos(a), sin(a)) * r;
    p.x /= iResolution.x / iResolution.y;
    return p + 0.5;
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float r = length(p);
    float edge = smoothstep(0.25, 0.65, r);
    vec2 kuv = kaleido(tc, 6.0);
    vec3 k = texture(samp, kuv).rgb;
    color = vec4(mix(c, k, edge * 0.85), 1.0);
}
