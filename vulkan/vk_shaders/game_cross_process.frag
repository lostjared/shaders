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

// Cross-process: cyan shadows + yellow highlights, classic indie-film grade.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 sh = c + vec3(-0.05, 0.02, 0.10) * (1.0 - lum);
    vec3 hi = sh + vec3(0.10, 0.08, -0.06) * lum;
    hi = (hi - 0.5) * 1.12 + 0.5;
    color = vec4(clamp(hi, 0.0, 1.0), 1.0);
}
