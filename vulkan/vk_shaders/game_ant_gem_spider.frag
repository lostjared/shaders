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

// Gem spider — faint radial spider-web overlay.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float a = atan(p.y, p.x);
    float r = length(p);
    float spoke = abs(sin(a * 6.0));
    float ring = abs(sin(r * 24.0));
    float web = max(smoothstep(0.88, 1.0, 1.0 - spoke), smoothstep(0.88, 1.0, 1.0 - ring));
    color = vec4(c - vec3(web) * 0.45, 1.0);
}
