#version 330 core
// Lo-fi ASCII / character cell effect using procedural glyph blocks.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

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
