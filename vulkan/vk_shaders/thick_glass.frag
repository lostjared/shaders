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
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 normCoord = gl_FragCoord.xy / iResolution.xy;
    float distortionStrength = 0.2;
    float noiseFactor = sin(normCoord.x * 10.0 + time_f) * cos(normCoord.y * 10.0 + time_f);
        vec2 distortedCoord = normCoord + distortionStrength * vec2(noiseFactor, noiseFactor);

    distortedCoord = clamp(distortedCoord, 0.0, 1.0);
    color = texture(samp, distortedCoord);
}
