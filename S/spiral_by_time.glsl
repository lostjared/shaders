#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

float h1(float n){ return fract(sin(n)*43758.5453123); }
vec2 h2(float n){ return fract(sin(vec2(n,n+1.0))*vec2(43758.5453,22578.1459)); }

void main(void) {
    float rate = 0.7;
    float t = time_f*rate;
    float t0 = floor(t);
    float a = fract(t);
    float w = a*a*(3.0-2.0*a);
    vec2 p0 = vec2(0.15) + h2(t0)*0.7;
    vec2 p1 = vec2(0.15) + h2(t0+1.0)*0.7;
    vec2 center = mix(p0, p1, w);

    vec2 off = tc - center;
    float maxR = length(vec2(0.5));
    float r = length(off);
    float nr = r / maxR + 1e-6;
    float ang = atan(off.y, off.x);

    float distortion = 0.5;
    float dr = nr + distortion*nr*nr;
    dr = clamp(dr, 0.0, 1.0)*maxR;

    float spiral = 3.0;
    ang += spiral*(1.0 - dr/maxR) + pingPong(time_f, 5.0);

    vec2 d = center + dr*vec2(cos(ang), sin(ang));

    vec2 rotc = vec2(0.5);
    vec2 q = d - rotc;
    float rot = 0.35*sin(time_f*0.6);
    float cs = cos(rot), sn = sin(rot);
    vec2 ruv = vec2(cs*q.x - sn*q.y, sn*q.x + cs*q.y) + rotc;

    vec2 warped;
    warped.x = pingPong(ruv.x + time_f*0.1, 1.0);
    warped.y = pingPong(ruv.y + time_f*0.1, 1.0);

    color = texture(samp, warped);
}
