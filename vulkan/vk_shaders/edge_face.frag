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
#define uDistortion ext.custom_uniforms[3].w
#define uPhaseRate ext.custom_uniforms[4].w
#define uRandRate ext.custom_uniforms[4].z
#define uRotateSpeed ext.custom_uniforms[4].x
#define uWarpSpeed ext.custom_uniforms[4].y

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
    vec2 center = vec2(0.5);
    vec2 off = tc - center;
    float maxR = length(vec2(0.5));
    float r = length(off);
    float nr = r / maxR;
    float ang = atan(off.y, off.x);

    float dr = nr + uDistortion * (nr * nr);
    dr = clamp(dr, 0.0, 1.0) * maxR;
    vec2 d = center + dr * vec2(cos(ang), sin(ang));
    vec2 dp = d - center;

    float tr = time_f * uRandRate;
    float tp = time_f * uPhaseRate;
    float nR = floor(tr);
    float nP = floor(tp);
    float ar = fract(tr);
    float ap = fract(tp);

    float dir0 = sign(rand(nR) - 0.5);
    float dir1 = sign(rand(nR + 1.0) - 0.5);
    float dir = mix(dir0, dir1, ar*ar*(3.0-2.0*ar));

    float ph0 = rand(nP) * 6.2831853;
    float ph1 = rand(nP + 1.0) * 6.2831853;
    float phase = mix(ph0, ph1, ap*ap*(3.0-2.0*ap));

    float rotA = dir * (phase + time_f * uRotateSpeed);
    mat2 rot = mat2(cos(rotA), -sin(rotA), sin(rotA), cos(rotA));
    vec2 rotp = rot * dp + center;

    float t = time_f * uWarpSpeed;
    vec2 w = vec2(pingPong(rotp.x + t, 1.0), pingPong(rotp.y + t, 1.0));

    color = texture(samp, w);
}
