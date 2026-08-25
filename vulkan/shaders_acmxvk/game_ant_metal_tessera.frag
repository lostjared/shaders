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

// Metal tessera — gentle mosaic tile borders.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * iResolution / 32.0;
    vec2 g = abs(fract(p) - 0.5);
    float edge = smoothstep(0.40, 0.50, max(g.x, g.y));
    color = vec4(mix(c, c * 0.55, edge * 0.85), 1.0);
}
