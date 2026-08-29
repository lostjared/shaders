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


void main(void) {
    float speed = 1.5;
    float amplitude = 0.02;
    float frequency = 6.0;
    float twist = 8.0;

    vec2 vortexCenter = vec2(-0.5, 1.5);
    vec2 adjustedTC = tc - vortexCenter;
    float angle = atan(adjustedTC.y, adjustedTC.x);
    float radius = length(adjustedTC);
    float vortex = sin(twist * angle + radius * frequency - time_f * speed) * amplitude * radius;

    vec2 vortexDistortedTC = tc + normalize(adjustedTC) * vortex;

    float whirlSpeed = 2.0;
    float whirlFrequency = 8.0;
    float whirlAmplitude = 0.03;
    float whirlScale = 0.5 + 0.5 * sin(time_f * whirlSpeed); // Expanding and contracting
    vec2 whirlCenter = vec2(0.5, 0.5);
    vec2 whirlAdjustedTC = (tc - whirlCenter) * whirlScale;
    float whirlAngle = atan(whirlAdjustedTC.y, whirlAdjustedTC.x);
    float whirlRadius = length(whirlAdjustedTC);
    float whirlDistortion = sin(whirlFrequency * whirlAngle + whirlRadius * whirlFrequency - time_f * whirlSpeed) * whirlAmplitude;

    vec2 whirlDistortedTC = tc + normalize(whirlAdjustedTC) * whirlDistortion;

    vec4 originalColor = texture(samp, tc);
    vec4 vortexColor = texture(samp, vortexDistortedTC);
    vec4 whirlColor = texture(samp, whirlDistortedTC);

    float lightEffect = sin(whirlRadius * 10.0 - time_f * 5.0) * 0.5 + 0.5;
    vec4 lightColor = vec4(1.0, 1.0, 1.0, 1.0) * lightEffect;

    color = mix(originalColor, mix(vortexColor, whirlColor, 0.5), 0.6 + 0.4 * sin(time_f));
    color += lightColor * (1.0 - lightEffect) * 0.3;
}
