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



void main(void) {
    vec4 texColor = texture(samp, tc);
    float r = texColor.r;
    float g = texColor.g;
    float b = texColor.b;
    color = vec4(
        dot(vec3(r, g, b), vec3(0.393, 0.769, 0.189)),
        dot(vec3(r, g, b), vec3(0.349, 0.686, 0.168)),
        dot(vec3(r, g, b), vec3(0.272, 0.534, 0.131)),
        texColor.a
    );
}
