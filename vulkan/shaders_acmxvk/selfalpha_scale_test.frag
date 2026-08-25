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
#define time_f ext.u2.y
#define time_speed ext.custom_uniforms[3].y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




void main(void) {
    float slider_scale = (uamp * time_f / time_speed);
    vec4 colorx = texture(samp, tc);
    colorx.rgb = (colorx.rgb * (sin(time_speed * slider_scale) * (uamp * 25.0)));
    ivec3 colori = ivec3(colorx.rgb * 255);
    colori = colori ^ ivec3(127);
    colori = colori % 255;
    color = vec4(sin(vec3(colori.rgb / 127.0) * slider_scale), 1.0);
} 