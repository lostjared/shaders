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

// Black-hole gravitational lens warp at the screen center.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 v = tc - 0.5;
    float r = length(v);
    float pull = 0.06 / (r * r + 0.04);
    vec2 dir = normalize(v + 1e-5);
    vec2 uv = tc - dir * pull * 0.02;
    vec3 c = texture(samp, uv).rgb;
    float core = smoothstep(0.10, 0.0, r);
    c = mix(c, vec3(0.0), core);
    float ringR = 0.18 + 0.01 * sin(time_f * 1.5);
    float ring = exp(-pow((r - ringR) * 30.0, 2.0));
    c += vec3(0.4, 0.2, 0.7) * ring;
    color = vec4(c, 1.0);
}
