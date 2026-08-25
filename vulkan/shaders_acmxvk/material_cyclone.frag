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
uniform sampler2D mat_samp;



void main(void) {
    vec2 normCoord = gl_FragCoord.xy / iResolution.xy;

    vec2 centeredCoord = normCoord - vec2(0.5, 0.5);
    centeredCoord.x *= iResolution.x / iResolution.y;
    float r = length(centeredCoord);
    float theta = atan(centeredCoord.y, centeredCoord.x);
    float twistAmount = 15.0;
    theta += (1.0 - r) * twistAmount * sin(time_f);
    vec2 twistedCoord = vec2(cos(theta), sin(theta)) * r;

    twistedCoord.x *= iResolution.y / iResolution.x;

    twistedCoord += vec2(0.5, 0.5);
    color = texture(samp, twistedCoord);
    vec4 color2 = texture(mat_samp, twistedCoord);
    color = mix(color, color2, 0.5);
}

