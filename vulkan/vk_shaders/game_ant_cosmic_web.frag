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

// Cosmic web — faint procedural starfield filament pattern.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 g = floor(tc * iResolution / 4.0);
    float h = hash(g);
    float twinkle = step(0.975, h) * (0.5 + 0.5 * sin(time_f * 2.0 + h * 30.0));
    vec2 p = tc - 0.5;
    float web = sin(p.x * 18.0) * sin(p.y * 18.0);
    web = smoothstep(0.70, 1.0, web) * 0.30;
    c += vec3(0.7, 0.8, 1.0) * (twinkle * 1.0 + web);
    color = vec4(c, 1.0);
}
