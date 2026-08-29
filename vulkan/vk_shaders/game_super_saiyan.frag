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

// Power-up aura: golden bloom on bright pixels, edge electricity.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;
    vec3 sum = vec3(0.0);
    for (int i = -2; i <= 2; ++i) {
        for (int j = -2; j <= 2; ++j) {
            sum += max(texture(samp, tc + vec2(i, j) * px * 2.0).rgb - 0.55, 0.0);
        }
    }
    sum /= 25.0;
    vec3 gold = sum * vec3(2.4, 1.9, 0.4);
    float flick = 0.85 + 0.15 * hash(floor(gl_FragCoord.xy * 0.1) + floor(time_f * 25.0));
    c += gold * flick;
    c.r += 0.05; c.g += 0.04;
    color = vec4(c, 1.0);
}
