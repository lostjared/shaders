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

// Metal vortex — soft swirling tint near center, no positional warp.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    float swirl = 0.5 + 0.5 * sin(a * 4.0 - r * 12.0 + time_f * 1.0);
    float mask = smoothstep(0.55, 0.0, r);
    vec3 tint = mix(vec3(0.45, 0.30, 0.95), vec3(0.95, 0.30, 0.60), swirl);
    color = vec4(c + tint * mask * 0.45, 1.0);
}
