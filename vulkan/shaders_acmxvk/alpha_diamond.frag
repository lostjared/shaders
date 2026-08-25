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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;


void main() {
    vec2 uv = tc;
    ivec2 coords = ivec2(uv * iResolution);

    vec4 origColor = texture(samp, uv);
    float pos = mod(time_f, 7.0) + 1.0;

    int x = coords.x;
    int y = coords.y;
    vec3 newColor = origColor.rgb;

    if ((x % 2) == 0) {
        if ((y % 2) == 0) {
            newColor.r = (1.0 - pos * origColor.r);
            newColor.b = (float(x + y) * pos) / 255.0;
        } else {
            newColor.r = (pos * origColor.r - float(y)) / 255.0;
            newColor.b = (float(x - y) * pos) / 255.0;
        }
    } else {
        if ((y % 2) == 0) {
            newColor.r = (pos * origColor.r - float(x)) / 255.0;
            newColor.b = (float(x - y) * pos) / 255.0;
        } else {
            newColor.r = (pos * origColor.r - float(y)) / 255.0;
            newColor.b = (float(x + y) * pos) / 255.0;
        }
    }

    float temp = newColor.r;
    newColor.r = newColor.b;
    newColor.b = temp;
    vec3 finalColor = (sin(time_f) > 0.0) ? vec3(1.0) - newColor : newColor;

    color = sin(vec4(finalColor, 1.0) * time_f);
    color.a = 1.0;
}
