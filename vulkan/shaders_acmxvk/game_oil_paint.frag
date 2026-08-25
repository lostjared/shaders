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

// Soft painterly look using a small Kuwahara-style box average.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



vec4 boxAvg(vec2 origin, vec2 px) {
    vec3 sum = vec3(0.0);
    vec3 sumSq = vec3(0.0);
    for (int x = 0; x < 3; ++x) {
        for (int y = 0; y < 3; ++y) {
            vec3 s = texture(samp, origin + vec2(float(x), float(y)) * px).rgb;
            sum += s;
            sumSq += s * s;
        }
    }
    vec3 mean = sum / 9.0;
    vec3 var = abs(sumSq / 9.0 - mean * mean);
    return vec4(mean, var.r + var.g + var.b);
}

void main(void) {
    vec2 px = 1.5 / iResolution;
    vec4 q0 = boxAvg(tc + vec2(-2.0, -2.0) * px, px);
    vec4 q1 = boxAvg(tc + vec2( 0.0, -2.0) * px, px);
    vec4 q2 = boxAvg(tc + vec2(-2.0,  0.0) * px, px);
    vec4 q3 = boxAvg(tc + vec2( 0.0,  0.0) * px, px);
    vec4 best = q0;
    if (q1.a < best.a) best = q1;
    if (q2.a < best.a) best = q2;
    if (q3.a < best.a) best = q3;
    color = vec4(best.rgb, 1.0);
}
