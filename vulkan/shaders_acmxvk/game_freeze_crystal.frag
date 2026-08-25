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

// Freeze: blue tint, reduced saturation, faceted ice tessellation distortion.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453) - 0.5;
}

void main(void) {
    vec2 g = floor(tc * 18.0);
    vec2 f = fract(tc * 18.0);
    vec2 jitter = hash2(g) * 0.3;
    vec2 facet = (f - 0.5 + jitter) * 0.012;
    vec3 c = texture(samp, tc + facet).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 ice = mix(vec3(0.55, 0.75, 1.0), vec3(0.95, 1.0, 1.05), lum);
    c = mix(c, ice, 0.55);
    float sparkle = step(0.985, fract(sin(dot(g, vec2(12.9, 78.2))) * 43758.0 + time_f));
    c += vec3(sparkle);
    color = vec4(c, 1.0);
}
