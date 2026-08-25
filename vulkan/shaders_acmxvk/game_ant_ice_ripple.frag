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

// Ice ripple — cool blue tint with soft expanding ripple highlights.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float r = length(p);
    float ripple = sin(r * 30.0 - time_f * 1.6);
    ripple = smoothstep(0.7, 1.0, ripple) * smoothstep(0.6, 0.0, r) * 0.55;
    vec3 ice = mix(c, c * vec3(0.78, 0.95, 1.20), 0.55);
    color = vec4(ice + vec3(0.7, 0.9, 1.0) * ripple, 1.0);
}
