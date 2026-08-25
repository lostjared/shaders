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
    float N = 8.0;
    vec2 center = vec2(0.5, 0.5);
    vec2 pos = tc - center;
    float angle = atan(pos.y, pos.x);
    float radius = length(pos);
    float speed = time_f * 0.05;
    angle += speed;
    angle = mod(angle, 6.2831853 / N);
    angle = abs(angle - (3.14159265 / N));
    vec2 kaleidoscopicTC;
    kaleidoscopicTC.x = radius * cos(angle);
    kaleidoscopicTC.y = radius * sin(angle);
    kaleidoscopicTC += center;
    vec2 warpedCoords;
    warpedCoords.x = fract(kaleidoscopicTC.x + time_f * 1.0);
    warpedCoords.y = fract(kaleidoscopicTC.y + time_f * 1.0);
    color = texture(samp, warpedCoords);
}
