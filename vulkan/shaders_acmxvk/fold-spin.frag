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
    vec2 uv = tc * 2.0 - 1.0;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);

    float spiralTime = mod(time_f, 4.0);
    float maxRadius = sqrt(2.0); 
    if (spiralTime < 2.0) {
        radius = mix(radius, maxRadius, spiralTime / 2.0);
    } else {
        radius = mix(maxRadius, radius, (spiralTime - 2.0) / 2.0);
    }
    angle += spiralTime * 3.14159;

    uv = vec2(cos(angle), sin(angle)) * radius;
    uv = (uv + 1.0) / 2.0;

    color = texture(samp, uv);
}
