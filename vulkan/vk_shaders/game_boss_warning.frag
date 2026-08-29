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

// Pulsing red boss-fight warning vignette with edge bands.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 v = tc - 0.5;
    float r = length(v);
    float pulse = 0.5 + 0.5 * sin(time_f * 6.0);
    float vig = smoothstep(0.25, 0.75, r);
    vec3 red = vec3(1.0, 0.05, 0.05);
    c = mix(c, c * 0.6 + red * 0.7, vig * (0.4 + 0.5 * pulse));
    float band = step(0.95, abs(tc.y - 0.5) * 2.0);
    c = mix(c, red, band * pulse * 0.9);
    color = vec4(c, 1.0);
}
