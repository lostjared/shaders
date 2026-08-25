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

// Molten web — lava-like cracked pattern under-glow on dark areas.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * 5.0;
    vec2 g = floor(p), f = fract(p);
    float d = 1.0;
    for (int j = -1; j <= 1; j++)
    for (int i = -1; i <= 1; i++) {
        vec2 o = vec2(i, j);
        float h = hash(g + o);
        vec2 r = o + vec2(0.5 + 0.5 * sin(h * 12.0 + time_f * 0.4),
                          0.5 + 0.5 * cos(h * 9.0 + time_f * 0.3)) - f;
        d = min(d, length(r));
    }
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float dark = smoothstep(0.6, 0.05, lum);
    float vein = smoothstep(0.10, 0.0, abs(d - 0.30)) * dark * 0.95;
    color = vec4(c + vec3(1.0, 0.45, 0.10) * vein, 1.0);
}
