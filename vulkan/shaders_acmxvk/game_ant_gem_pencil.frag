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

// Gem pencil — light pencil-sketch hatching overlay, low intensity.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec2 px = tc * iResolution;
    float h1 = sin((px.x + px.y) * 0.6);
    float h2 = sin((px.x - px.y) * 0.6);
    float hatch = (smoothstep(0.5, 0.0, lum) * smoothstep(0.0, 0.4, h1)
                 + smoothstep(0.7, 0.2, lum) * smoothstep(0.0, 0.4, h2));
    color = vec4(c * (1.0 - hatch * 0.55), 1.0);
}
