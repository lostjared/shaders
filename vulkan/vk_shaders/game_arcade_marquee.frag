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

// Arcade marquee: scrolling rainbow light bars on top and bottom edges.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



vec3 hue(float h) {
    return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float bar = 0.06;
    float topD  = smoothstep(bar, 0.0, tc.y);
    float botD  = smoothstep(1.0 - bar, 1.0, tc.y);
    float mask  = max(topD, botD);
    float bulb  = step(0.5, fract(tc.x * 28.0 + time_f * 0.6));
    vec3 marquee = hue(tc.x * 0.7 + time_f * 0.25) * (0.6 + 0.4 * bulb);
    c = mix(c, marquee, mask * 0.85);
    color = vec4(c, 1.0);
}
