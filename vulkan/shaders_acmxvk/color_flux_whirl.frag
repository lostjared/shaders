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



layout(set = 0, binding = 0) uniform sampler2D samp;
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

vec4 xor_RGB(vec4 icolor, vec4 source) {
    ivec3 int_color;
    ivec4 isource = ivec4(source * 255);
    for (int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * icolor[i]);
        int_color[i] = int_color[i] ^ isource[i];
        if (int_color[i] > 255)
            int_color[i] = int_color[i] % 255;
        icolor[i] = float(int_color[i]) / 255;
    }
    icolor.a = 1.0;
return icolor;
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main() {
    vec2 uv = tc - 0.5;
    uv.y *= iResolution.y / iResolution.x;
    float intensity = pingPong(time_f, 10.0);
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    float swirl = sin(time_f * 0.5) * 0.5 + 0.5;
    angle += intensity * swirl * sin(radius * 10.0 + time_f);
    uv = vec2(cos(angle), sin(angle)) * radius;
    vec4 texColor = texture(samp, uv + 0.5);
    float fluctuation = sin(time_f * 2.0) * 0.5 + 0.5;
    vec4 fluctuatedColor = vec4(mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), fluctuation), 1.0);
    vec4 xorResult = xor_RGB(texColor, fluctuatedColor);
    color = mix(texColor, xorResult, 0.5);
}

