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

// Disco floor: animated colored tile overlay, multiplied with the source.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

vec3 hue(float h) {
    return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void main(void) {
    vec3 src = texture(samp, tc).rgb;
    vec2 cell = floor(tc * vec2(16.0, 9.0));
    float seed = hash(cell);
    float beat = step(0.5, fract(time_f * 1.5 + seed));
    vec3 tile = hue(seed + time_f * 0.2);
    vec3 mixed = src * mix(vec3(0.7), tile * 1.6, beat * 0.7);
    color = vec4(mixed, 1.0);
}
