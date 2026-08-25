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

// Center-sharp, edges blurred. Cinematic depth-of-field fake.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 px = 1.0 / iResolution;
    vec2 v = tc - 0.5;
    float k = smoothstep(0.05, 0.45, dot(v, v));
    vec3 sum = vec3(0.0);
    float total = 0.0;
    for (int i = -2; i <= 2; ++i) {
        for (int j = -2; j <= 2; ++j) {
            vec2 o = vec2(float(i), float(j)) * px * (1.5 + 4.0 * k);
            float w = exp(-(float(i*i + j*j)) * 0.4);
            sum += texture(samp, tc + o).rgb * w;
            total += w;
        }
    }
    color = vec4(sum / total, 1.0);
}
