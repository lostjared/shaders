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


float PI = 3.1415926535897932384626433832795;
layout(set = 0, binding = 0) uniform sampler2D samp;

vec4 xor_RGB(vec4 icolor, vec4 isourcex) {
    ivec4 isource = ivec4(isourcex * 255);
    ivec3 int_color;
    for(int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * icolor[i]);
        int_color[i] ^= isource[i];
        if(int_color[i] > 255)
            int_color[i] %= 255;
        icolor[i] = float(int_color[i]) / 255.0;
    }
    icolor.a = 1.0;
return icolor;
}


void main() {
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;
    float plasma = 0.0;
    plasma += sin((uv.x + time_f) * 5.0);
    plasma += sin((uv.y + time_f) * 5.0);
    plasma += sin((uv.x + uv.y + time_f) * 5.0);
    plasma += cos(length(uv + time_f) * 10.0);
    plasma *= 0.25;
    vec3 col;
    col.r = cos(plasma * PI + time_f * 0.2) * 0.5 + 0.5;
    col.g = sin(plasma * PI + time_f * 0.2) * 0.5 + 0.5;
    col.b = sin(plasma * PI + time_f * 0.4) * 0.5 + 0.5;
    color = vec4(col, 1.0);
    color = xor_RGB(color, texture(samp, tc));
}


