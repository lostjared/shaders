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

// Glass mandala — circular faceted vignette overlay (geometric, non-distorting).
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    float seg = 8.0;
    float facet = abs(mod(a, 6.2831 / seg) - 3.1416 / seg);
    float ring = smoothstep(0.10, 0.0, abs(facet - 0.2)) * smoothstep(0.65, 0.20, r);
    color = vec4(c + vec3(0.8, 0.92, 1.15) * ring * 0.55, 1.0);
}
