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

// Magic / arcane purple aura grade.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 arcane = mix(c, vec3(lum) * vec3(0.65, 0.35, 1.00), 0.40);
    vec2 v = tc - 0.5;
    float halo = smoothstep(0.55, 0.10, dot(v, v));
    arcane += vec3(0.18, 0.06, 0.30) * halo * 0.35;
    color = vec4(clamp(arcane, 0.0, 1.0), 1.0);
}
