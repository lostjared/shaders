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

// Freeze frame: icy desaturation, frost veins, and cold vignette.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec2 p = tc - 0.5;
    float vein = pow(abs(sin((p.x + p.y) * 45.0 + sin(p.x * 20.0) * 3.0)), 18.0);
    float edge = smoothstep(0.08, 0.42, dot(p, p));
    vec3 ice = mix(vec3(lum), vec3(0.55, 0.85, 1.0), 0.45);
    c = mix(c, ice, 0.65);
    c += vec3(0.5, 0.85, 1.0) * (vein * 0.35 + edge * 0.25);
    color = vec4(c, 1.0);
}
