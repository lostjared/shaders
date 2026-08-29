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

// Lo-fi ASCII / character cell effect using procedural glyph blocks.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float glyph(vec2 p, float lum) {
    // p in [0,1] inside a cell; lum picks a different glyph mask shape.
    p = p * 2.0 - 1.0;
    float d = length(p);
    if (lum < 0.15) return 0.0;
    if (lum < 0.30) return step(0.85, 1.0 - d);                              // .
    if (lum < 0.45) return step(abs(p.y), 0.15);                             // -
    if (lum < 0.60) return max(step(abs(p.x), 0.15), step(abs(p.y), 0.15));  // +
    if (lum < 0.75) return step(d, 0.7);                                     // o
    if (lum < 0.90) return step(max(abs(p.x), abs(p.y)), 0.75);              // []
    return 1.0;                                                              // #
}

void main(void) {
    float cell = 8.0;
    vec2 px = vec2(cell) / iResolution;
    vec2 cellUV = floor(tc / px) * px + px * 0.5;
    vec3 src = texture(samp, cellUV).rgb;
    float lum = dot(src, vec3(0.299, 0.587, 0.114));
    vec2 inCell = fract(tc / px);
    float g = glyph(inCell, lum);
    vec3 fg = src * 1.15;
    vec3 bg = src * 0.15;
    color = vec4(mix(bg, fg, g), 1.0);
}
