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

// Metal helix — twin spiral sheen lines around screen, faint.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float a = atan(p.y, p.x);
    float r = length(p);
    float h1 = sin(a * 2.0 + r * 18.0 - time_f * 0.5);
    float h2 = sin(a * 2.0 + r * 18.0 - time_f * 0.5 + 3.14159);
    float helix = max(smoothstep(0.85, 1.0, h1), smoothstep(0.85, 1.0, h2));
    color = vec4(c + vec3(0.85, 0.92, 1.10) * helix * 0.50, 1.0);
}
