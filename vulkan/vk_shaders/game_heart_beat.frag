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

// Low-HP heartbeat: red vignette pulses with a thump-thump rhythm.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float beat(float t) {
    float p = mod(t, 1.0);
    float a = exp(-pow((p - 0.10) * 8.0, 2.0));
    float b = exp(-pow((p - 0.28) * 8.0, 2.0)) * 0.7;
    return a + b;
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float r = length(tc - 0.5);
    float vig = smoothstep(0.20, 0.85, r);
    float h = beat(time_f * 0.9);
    vec3 red = vec3(0.95, 0.05, 0.05);
    c = mix(c, c * 0.7 + red, vig * h * 0.85);
    float pulse = 1.0 + 0.04 * h;
    c *= pulse;
    color = vec4(c, 1.0);
}
