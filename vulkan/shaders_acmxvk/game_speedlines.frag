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

// Anime-style radial speed lines from screen center.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(float n) { return fract(sin(n) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 v = tc - 0.5;
    float a = atan(v.y, v.x);
    float r = length(v);
    float spokes = 64.0;
    float idx = floor(a / (6.2831853 / spokes));
    float seed = hash(idx);
    float band = step(0.5, fract(seed * 7.0 + time_f * (0.5 + seed)));
    float reach = smoothstep(0.18, 0.55, r) * band;
    vec3 line = mix(c, vec3(1.0), reach * 0.85);
    color = vec4(line, 1.0);
}
