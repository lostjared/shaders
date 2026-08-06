#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform float uamp;
uniform float time_speed;

void main(void) {
    vec4 colorx = texture(samp, tc);
    colorx.rgb += (colorx.rgb * (time_speed * (uamp * 5.0)));
    ivec3 colori = ivec3(colorx.rgb * 255);
    colori = colori ^ ivec3(127);
    colori = colori % 255;
    color = vec4(vec3(colori.rgb / 255.0), 1.0);
} 