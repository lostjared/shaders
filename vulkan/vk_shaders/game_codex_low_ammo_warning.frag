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

// Low ammo warning: amber HUD stripes with rhythmic edge pulse.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float pulse = 0.5 + 0.5 * sin(time_f * 5.5);
    float stripe = step(0.55, fract((tc.x + tc.y) * 18.0 - time_f * 1.8));
    float frame = max(smoothstep(0.16, 0.0, tc.x), smoothstep(0.84, 1.0, tc.x));
    frame = max(frame, max(smoothstep(0.13, 0.0, tc.y), smoothstep(0.87, 1.0, tc.y)));
    vec3 amber = vec3(1.0, 0.62, 0.08);
    c = mix(c, amber, frame * stripe * pulse * 0.55);
    color = vec4(c, 1.0);
}
