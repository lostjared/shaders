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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;


layout(set = 0, binding = 0) uniform sampler2D samp;

float PI = 3.1415926535897932384626433832795;

void main() {
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;
    
    float plasma = 0.0;
    plasma += sin((uv.x + time_f) * 5.0);
    plasma += sin((uv.y + time_f) * 5.0);
    plasma += sin((uv.x + uv.y + time_f) * 5.0);
    plasma += cos(length(uv + time_f) * 10.0);
    plasma *= 0.25;

    vec3 baseColor;
    baseColor.r = cos(plasma * PI + time_f * 0.2) * 0.5 + 0.5;
    baseColor.g = sin(plasma * PI + time_f * 0.2) * 0.5 + 0.5;
    baseColor.b = sin(plasma * PI + time_f * 0.4) * 0.5 + 0.5;

    float dispersion = 0.02;
    vec3 prismColor;
    prismColor.r = texture(samp, tc + vec2(dispersion, 0.0)).r;
    prismColor.g = texture(samp, tc).g;
    prismColor.b = texture(samp, tc - vec2(dispersion, 0.0)).b;

    color = vec4(mix(baseColor, prismColor, 0.6), 1.0);
}

