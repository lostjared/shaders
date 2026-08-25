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

// Subtle underwater wobble + cool blue-green tint + soft caustic shimmer.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 uv = tc;
    uv.x += sin(uv.y * 14.0 + time_f * 1.4) * 0.004;
    uv.y += sin(uv.x * 11.0 - time_f * 1.1) * 0.004;
    vec3 c = texture(samp, uv).rgb;
    c *= vec3(0.78, 1.00, 1.10);
    float caustic = 0.5 + 0.5 * sin(uv.x * 30.0 + time_f * 1.5) * sin(uv.y * 28.0 - time_f * 1.2);
    c += vec3(0.04, 0.07, 0.10) * pow(caustic, 3.0);
    vec2 v = tc - 0.5;
    c *= mix(0.7, 1.0, smoothstep(0.7, 0.05, dot(v, v)));
    color = vec4(c, 1.0);
}
