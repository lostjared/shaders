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

// Original Game Boy DMG 4-tone green palette quantization.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 p0 = vec3(0.06, 0.22, 0.06);
    vec3 p1 = vec3(0.19, 0.38, 0.19);
    vec3 p2 = vec3(0.55, 0.67, 0.06);
    vec3 p3 = vec3(0.61, 0.74, 0.06);
    vec3 quant;
    if (lum < 0.25)      quant = p0;
    else if (lum < 0.5)  quant = p1;
    else if (lum < 0.75) quant = p2;
    else                 quant = p3;
    color = vec4(quant, 1.0);
}
