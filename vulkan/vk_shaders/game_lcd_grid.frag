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

// Handheld-style LCD pixel grid. Adds dot-matrix character to retro/pixel games.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 cell = fract(gl_FragCoord.xy / 2.0);
    float gx = smoothstep(0.0, 0.15, cell.x) * (1.0 - smoothstep(0.85, 1.0, cell.x));
    float gy = smoothstep(0.0, 0.15, cell.y) * (1.0 - smoothstep(0.85, 1.0, cell.y));
    float grid = mix(0.78, 1.0, gx * gy);
    color = vec4(c * grid, 1.0);
}
