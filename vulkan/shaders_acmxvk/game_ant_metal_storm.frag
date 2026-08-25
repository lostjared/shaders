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

// Metal storm — random global flicker like a stormy sky, mild.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(float x) { return fract(sin(x) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float t = floor(time_f * 8.0);
    float flick = hash(t);
    float spike = step(0.85, flick);
    vec3 storm = c * (1.0 + spike * 0.55);
    float top = smoothstep(0.7, 0.0, tc.y);
    storm += vec3(0.7, 0.85, 1.10) * spike * top * 0.30;
    color = vec4(storm, 1.0);
}
