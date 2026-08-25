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

// Simulated CRT phosphor afterglow using mild blur and additive ghost.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;
    vec3 ghost = (texture(samp, tc + vec2(px.x, 0.0)).rgb +
                  texture(samp, tc - vec2(px.x, 0.0)).rgb +
                  texture(samp, tc + vec2(0.0, px.y)).rgb +
                  texture(samp, tc - vec2(0.0, px.y)).rgb) * 0.25;
    vec3 outc = c + max(ghost - 0.55, 0.0) * 0.6;
    float scan = 0.92 + 0.08 * sin(gl_FragCoord.y * 1.2);
    color = vec4(outc * scan, 1.0);
}
