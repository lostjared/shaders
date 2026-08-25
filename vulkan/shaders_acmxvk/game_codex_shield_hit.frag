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

// Shield hit: hex energy shimmer with a pulsing blue edge flash.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    float r = length(p);
    float hex = abs(sin((p.x * 18.0 + p.y * 10.0) + time_f * 4.0));
    hex *= abs(sin((p.x * -18.0 + p.y * 10.0) - time_f * 3.2));
    float ring = exp(-pow((r - mod(time_f * 0.45, 0.9)) * 18.0, 2.0));
    vec3 c = texture(samp, tc + normalize(p + 1e-5) * ring * 0.025).rgb;
    vec3 shield = vec3(0.2, 0.75, 1.0) * (pow(hex, 10.0) * 0.45 + ring * 0.9);
    color = vec4(c + shield, 1.0);
}
