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

void main(void) {
    float time_t = pingPong(time_f, 7.0);
    vec3 neonPurple = vec3(199.0/255.0, 0.0, 1.0);
    vec3 neonPink   = vec3(1.0, 0.0, 127.0/255.0);
    vec3 gradientColor = mix(neonPink, neonPurple, tc.y);
    color = mix(vec4(sin(gradientColor * time_t), 1.0), texture(samp, tc), 0.5);
}
