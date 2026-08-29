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

// Cel-shaded look: posterize colors + Sobel ink outlines.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main(void) {
    vec2 px = 1.0 / iResolution;
    float tl = lum(texture(samp, tc + px * vec2(-1, -1)).rgb);
    float t  = lum(texture(samp, tc + px * vec2( 0, -1)).rgb);
    float tr = lum(texture(samp, tc + px * vec2( 1, -1)).rgb);
    float l  = lum(texture(samp, tc + px * vec2(-1,  0)).rgb);
    float r  = lum(texture(samp, tc + px * vec2( 1,  0)).rgb);
    float bl = lum(texture(samp, tc + px * vec2(-1,  1)).rgb);
    float b  = lum(texture(samp, tc + px * vec2( 0,  1)).rgb);
    float br = lum(texture(samp, tc + px * vec2( 1,  1)).rgb);
    float gx = -tl - 2.0*l - bl + tr + 2.0*r + br;
    float gy = -tl - 2.0*t - tr + bl + 2.0*b + br;
    float edge = smoothstep(0.4, 0.9, length(vec2(gx, gy)));
    vec3 c = texture(samp, tc).rgb;
    c = floor(c * 5.0 + 0.5) / 5.0;
    c *= (1.0 - edge);
    color = vec4(c, 1.0);
}
