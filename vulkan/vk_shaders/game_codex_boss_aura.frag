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

// Boss aura: hostile purple vignette and rotating radial pressure waves.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float rays = pow(0.5 + 0.5 * sin(a * 9.0 + r * 18.0 - time_f * 3.0), 5.0);
    float edge = smoothstep(0.12, 0.58, r);
    vec3 c = texture(samp, tc).rgb;
    vec3 aura = vec3(0.7, 0.05, 1.0) * (edge * 0.55 + rays * 0.28);
    c = mix(c, c * vec3(0.85, 0.65, 1.05), edge * 0.45) + aura;
    color = vec4(c, 1.0);
}
