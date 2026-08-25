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

// Lava-world tint with rising heat distortion at the bottom.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    float heatAmt = pow(1.0 - tc.y, 1.5);
    vec2 uv = tc;
    uv.x += sin(tc.y * 30.0 + time_f * 4.0) * 0.006 * heatAmt;
    uv.y += cos(tc.x * 24.0 + time_f * 3.0) * 0.004 * heatAmt;
    vec3 c = texture(samp, uv).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 lava = mix(vec3(0.18, 0.02, 0.0), vec3(1.4, 0.8, 0.15), pow(lum, 0.8));
    c = mix(c, lava, 0.55);
    c += vec3(0.5, 0.15, 0.0) * heatAmt * 0.18;
    color = vec4(c, 1.0);
}
