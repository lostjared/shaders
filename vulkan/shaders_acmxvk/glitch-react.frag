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



float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

vec2 glitchEffect(vec2 uv, float timeAmp) {
    float time = floor(timeAmp);
    float amp = fract(timeAmp);
    uv.y += amp * 0.1 * sin(time * 10.0 + uv.x * 100.0);
    uv.x += amp * 0.05 * sin(time * 5.0 + uv.y * 200.0);
    uv.x += rand(vec2(uv.y * time, uv.x)) * 0.1 * amp;
    uv.y += rand(vec2(uv.x * time, uv.y)) * 0.1 * amp;
    return uv;
}

void main(void) {
    vec2 uv = tc;
    uv = glitchEffect(uv, time_f);
    color = texture(samp, uv);
}
