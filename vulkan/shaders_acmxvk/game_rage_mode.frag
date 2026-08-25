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

// Rage mode: zoom punch-in, red overlay, RGB split, vignette.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 v = tc - 0.5;
    float zoom = 0.92 + 0.02 * sin(time_f * 8.0);
    v *= zoom;
    vec2 uv = v + 0.5;
    float k = length(v) * 0.04;
    vec2 dir = normalize(v + 1e-5);
    float r = texture(samp, uv + dir * k).r;
    float g = texture(samp, uv).g;
    float b = texture(samp, uv - dir * k).b;
    vec3 c = vec3(r, g, b);
    c.r = min(c.r * 1.25 + 0.1, 1.4);
    c.g *= 0.85;
    c.b *= 0.85;
    float vig = smoothstep(0.85, 0.3, length(v));
    c *= vig;
    color = vec4(c, 1.0);
}
