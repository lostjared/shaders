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
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    vec2 normCoord = tc;

    float timeAdjustedFrequency = 10.0 + sin(time_f) * 5.0;
    float timeAdjustedAmplitude = 0.01 + (sin(time_f * 0.5) * 0.5 + 0.5) * 0.05;
    float zigzagFactor = abs(fract(normCoord.y * timeAdjustedFrequency) - 0.5) * 2.0;
    float xDisplacement = zigzagFactor * timeAdjustedAmplitude;
    vec2 displacedCoord = vec2(normCoord.x + xDisplacement, normCoord.y);
    displacedCoord = clamp(displacedCoord, 0.0, 1.0);

    vec4 texColor = texture(samp, displacedCoord);

    float noise = rand(displacedCoord * time_f) * 0.1;
    float line = step(0.995, rand(vec2(displacedCoord.y * 100.0, time_f * 0.1)));

    texColor.rgb += noise;
    texColor.rgb = mix(texColor.rgb, vec3(0.0), line * 0.5);

    color = texColor;
}
