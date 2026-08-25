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
    float t = mod(time_f, 10.0);
    float scale = pow(1.1, t);

    vec2 centeredTC = (tc - 0.5) * scale + 0.5;
    
    float xDistort = cos(centeredTC.y * 10.0 + time_f) * 0.1 / scale;
    float yDistort = sin(centeredTC.x * 10.0 + time_f) * 0.1 / scale;
    float tanDistortX = tan(centeredTC.x * 5.0 + time_f) * 0.05 / scale;
    float tanDistortY = tan(centeredTC.y * 5.0 + time_f) * 0.05 / scale;

    vec2 distortedTC = centeredTC + vec2(xDistort + tanDistortX, yDistort + tanDistortY);
    distortedTC = fract(distortedTC);

    color = texture(samp, distortedTC);
}
