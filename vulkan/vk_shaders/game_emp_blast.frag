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

// EMP blast: expanding shockwave ring with color invert inside the wave.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 v = tc - 0.5;
    float r = length(v);
    float wave = mod(time_f * 0.6, 1.4);
    float ring = exp(-pow((r - wave) * 14.0, 2.0));
    vec2 dir = normalize(v + 1e-5);
    vec3 c = texture(samp, tc - dir * ring * 0.04).rgb;
    if (r < wave) {
        c = mix(c, 1.0 - c, smoothstep(0.0, 0.15, wave - r) * 0.6);
    }
    c += vec3(0.4, 0.7, 1.0) * ring;
    color = vec4(c, 1.0);
}
