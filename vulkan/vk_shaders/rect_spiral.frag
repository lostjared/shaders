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
    float loop_dur = 20.0;
    float current_t = mod(time_f, loop_dur);
    vec2 uv = (tc - 0.5) * (iResolution.x / iResolution.y, 1.0);
    float radius = length(uv);
    float angle = atan(uv.y, uv.x);
    float spiralSpeed = 1.0;
    angle += current_t * spiralSpeed;
    radius *= current_t;     vec2 spiralCoord = vec2(cos(angle), sin(angle)) * radius;

    vec2 transformedCoord = sin(spiralCoord * radius/2);
    
    vec2 finalCoord = transformedCoord * 0.5 + 0.5;
    color = texture(samp, finalCoord);
}
