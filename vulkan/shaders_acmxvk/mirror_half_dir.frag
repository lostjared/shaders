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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void)
{
    vec2 uv = tc;
    float duration = 2.0;
    float totalDuration = 2.0 * duration;
    float currentTime = mod(time_f, totalDuration);

    if (currentTime < duration) {
        if (uv.x > 0.5) {
            uv.x = 1.0 - uv.x;
        }
    } else {
        if (uv.x < 0.5) {
            uv.x = 1.0 - uv.x;
        }
    }
    
    color = texture(samp, uv);
}
