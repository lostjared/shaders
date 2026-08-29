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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




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
