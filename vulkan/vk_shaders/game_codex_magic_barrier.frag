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

// Magic barrier: circular runes and teal refraction.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float glyphs = step(0.86, sin(a * 24.0 + time_f * 2.0) * 0.5 + 0.5);
    float rings = smoothstep(0.018, 0.0, abs(fract(r * 8.0 - time_f * 0.25) - 0.5) - 0.46);
    float mask = glyphs * rings * smoothstep(0.58, 0.18, r);
    vec2 uv = tc + normalize(p + 1e-5) * mask * 0.035;
    vec3 c = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    c += vec3(0.0, 0.9, 0.75) * mask;
    color = vec4(c, 1.0);
}
