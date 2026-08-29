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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float rand(float seed) {
    return fract(sin(seed) * 43758.5453123);
}

vec2 randomPos(float seed) {
    return vec2(rand(seed), rand(seed + 1.0));
}

vec2 expand(vec2 pos, vec2 center) {
    float t = mod(time_f, 4.0);
    float scale = abs(sin(t * 3.14159 / 2.0));
    return mix(center, pos, scale);
}

void main(void) {
    float cycle = floor(time_f / 4.0);
    vec2 center = randomPos(cycle);
    vec2 pos = expand(tc, center);
    vec4 tcolor = texture(samp, pos);
    color = tcolor;
}
