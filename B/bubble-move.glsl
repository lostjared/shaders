#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float h1(float n){return fract(sin(n)*43758.5453123);}
vec2 h2(float n){return fract(sin(vec2(n,n+1.0))*vec2(43758.5453,22578.1459));}

void main(void){
    float rate = 0.4;
    float t = time_f*rate;
    float t0 = floor(t);
    float a = fract(t);
    float s = a*a*(3.0-2.0*a);

    vec2 p0 = 0.2 + h2(t0)*0.6;
    vec2 p1 = 0.2 + h2(t0+1.0)*0.6;
    vec2 center = mix(p0,p1,s);

    float r0 = 0.35 + 0.1*h1(t0*1.7);
    float r1 = 0.35 + 0.1*h1((t0+1.0)*1.7);
    float radius = mix(r0,r1,s);

    vec2 uv = tc;
    vec2 d = uv - center;
    float len = length(d)/radius;

    float wob = 0.12 + 0.06*h1(t0*2.3);
    vec2 distort = d * (1.0 + wob * sin(time_f*1.6 + len*22.0));
    vec2 coord = clamp(center + distort, 0.001, 0.999);

    vec4 texColor = texture(samp, coord);
    float bubble = smoothstep(0.8, 1.0, 1.0 - len);
    color = mix(texColor, vec4(1.0), bubble);
}
