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

// Metal shard — angular triangular shard highlights, static, faint.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * 8.0;
    vec2 g = floor(p), f = fract(p);
    float tri = step(f.x + f.y, 1.0);
    float h = hash(g + tri);
    float sh = (0.5 + 0.5 * sin(time_f * 0.8 + h * 6.0)) * step(0.55, h) * 0.40;
    color = vec4(c + vec3(0.85, 0.95, 1.10) * sh, 1.0);
}
