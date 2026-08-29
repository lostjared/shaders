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

// Metal fracture — faint static crack overlay, mostly transparent.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * 6.0;
    vec2 g = floor(p), f = fract(p);
    float d = 1.0;
    for (int j = -1; j <= 1; j++)
    for (int i = -1; i <= 1; i++) {
        vec2 o = vec2(i, j);
        vec2 r = o + vec2(hash(g + o), hash(g + o + 7.0)) - f;
        d = min(d, dot(r, r));
    }
    float crack = smoothstep(0.005, 0.0, d - 0.02) * 0.60;
    color = vec4(c - vec3(crack) * 0.7 + vec3(0.05, 0.10, 0.20) * crack, 1.0);
}
