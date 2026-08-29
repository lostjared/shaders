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



float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main() {
    float displacement = pingPong(tc.x * iResolution.x + time_f * 50.0, 20.0);
    vec2 distortedTC = vec2(
        atan(tc.y - 0.5, tc.x - 0.5) / 3.14159 + 0.5,
        tc.y + sin(time_f * 2.0) * 0.02
    );
    distortedTC.x += displacement / iResolution.x;
    color = texture(samp, sin(distortedTC * time_f));
}
