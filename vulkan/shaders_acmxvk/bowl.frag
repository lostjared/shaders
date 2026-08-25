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



float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return abs(m - len);
}

float rand(float n) {
    return fract(sin(n) * 43758.5453123);
}

void main(void) {
    vec2 center = vec2(0.5, 0.5);
    vec2 off = tc - center;
    float maxR = length(vec2(0.5));
    float r = length(off);
    float nr = r / maxR;
    float ang = atan(off.y, off.x);

    float distortion = 0.5;
    float dr = nr + distortion * (nr * nr);
    dr = clamp(dr, 0.0, 1.0) * maxR;
    vec2 d = center + dr * vec2(cos(ang), sin(ang));

    float dir = sign(rand(floor(time_f * 0.2)) - 0.5);
    float phase = rand(floor(time_f * 0.1)) * 6.2831853;
    float rotateSpeed = 1.0;
    float warpSpeed = 0.1;

    ang += dir * (phase + time_f * rotateSpeed);

    vec2 dp = d - center;
    float ca = cos(ang), sa = sin(ang);
    vec2 rot = vec2(ca * dp.x - sa * dp.y, sa * dp.x + ca * dp.y) + center;

    float t = time_f * warpSpeed;
    vec2 w = vec2(pingPong(rot.x + t, 1.0), pingPong(rot.y + t, 1.0));

    color = texture(samp, w);
}
