#version 330 core
in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

float ripplePulse(vec2 uv, vec2 c, float t0){
    float d = length(uv - c);
    float k = 28.0;
    float w = 8.0;
    float a = sin(d * k - (time_f - t0) * w);
    float falloff = exp(-d * 5.5);
    float gate = smoothstep(0.0, 0.4, time_f - t0) * step(time_f - t0, 2.6);
    return a * falloff * gate;
}

void main(){
    vec2 uv = tc;
    vec2 mouse = iMouse.xy / iResolution.xy;

    float interval = 1.25;
    float baseStart = floor(time_f / interval) * interval;

    float r = 0.0;
    r += ripplePulse(uv, mouse, baseStart - 0.0*interval);
    r += ripplePulse(uv, mouse, baseStart - 1.0*interval);
    r += ripplePulse(uv, mouse, baseStart - 2.0*interval);

    vec2 dir = normalize(uv - mouse + 1e-6);
    float amp = 0.08;              // ~4x the original 0.02
    vec2 offset = dir * r * amp;

    vec4 col = texture(samp, uv + offset);
    color = col;
}
