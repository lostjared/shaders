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

// Thermal/IR vision palette mapped from luminance.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



vec3 thermalRamp(float t) {
    t = clamp(t, 0.0, 1.0);
    vec3 c0 = vec3(0.00, 0.00, 0.10);
    vec3 c1 = vec3(0.10, 0.00, 0.55);
    vec3 c2 = vec3(0.85, 0.10, 0.65);
    vec3 c3 = vec3(1.00, 0.55, 0.10);
    vec3 c4 = vec3(1.00, 0.95, 0.55);
    if (t < 0.25) return mix(c0, c1, t / 0.25);
    if (t < 0.5)  return mix(c1, c2, (t - 0.25) / 0.25);
    if (t < 0.75) return mix(c2, c3, (t - 0.5)  / 0.25);
    return mix(c3, c4, (t - 0.75) / 0.25);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    color = vec4(thermalRamp(lum), 1.0);
}
