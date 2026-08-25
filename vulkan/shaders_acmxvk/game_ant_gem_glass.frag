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

// Gem glass — frosted glass softening at frame edges only.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 ts = 1.5 / iResolution;
    vec3 b = (texture(samp, tc + ts).rgb + texture(samp, tc - ts).rgb
            + texture(samp, tc + vec2(ts.x, -ts.y)).rgb
            + texture(samp, tc + vec2(-ts.x, ts.y)).rgb) * 0.25;
    vec2 p = tc - 0.5;
    float edge = smoothstep(0.15, 0.55, length(p));
    color = vec4(mix(c, b, edge * 1.0), 1.0);
}
