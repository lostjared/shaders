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
    vec2 uv = tc - vec2(0.5);
    float radius = length(uv) * 2.0;

    float frequency = 10.0;
    float amplitude = 0.1;

    float pulsate = amplitude * sin(time_f * frequency);
float adjustedRadius = clamp(radius + pulsate, 0.0, 1.0);

    vec3 neonBlue = vec3(0.0, 1.0, 1.0);
    vec3 neonPink = vec3(1.0, 0.0, 0.5);
    vec3 gradientColor = mix(neonBlue, neonPink, adjustedRadius);\
    vec4 texColor = texture(samp, tc);
    vec3 finalColor = texColor.rgb * gradientColor;
    color = vec4(sin(finalColor * time_f), texColor.a);
}
