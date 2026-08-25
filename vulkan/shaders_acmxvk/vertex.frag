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


layout (location=0) in vec3 pos;
layout (location=1) in vec2 texCoord;

out vec2 tc;
uniform mat4 mv_matrix;
uniform mat4 proj_matrix;

void main() {
    gl_Position = proj_matrix * mv_matrix * vec4(pos,1.0);
    tc = texCoord;
}
