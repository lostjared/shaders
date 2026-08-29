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

// Subtle screen-space ambient occlusion fake using local darkening of edges.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;
    float lumC = dot(c, vec3(0.299, 0.587, 0.114));
    float occ = 0.0;
    for (int i = 0; i < 8; ++i) {
        float a = float(i) * 0.7853981;
        vec2 o = vec2(cos(a), sin(a)) * px * 2.0;
        float lumS = dot(texture(samp, tc + o).rgb, vec3(0.299, 0.587, 0.114));
        occ += max(0.0, lumC - lumS);
    }
    occ = clamp(occ * 0.9, 0.0, 0.45);
    color = vec4(c * (1.0 - occ), 1.0);
}
