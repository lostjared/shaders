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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);

    int numSpokes = 32;
    float spokeWidth = 0.05;
    float spokeAngle = radians(360.0 / float(numSpokes));
    float spokePattern = mod(angle + time_f * 2.0, spokeAngle) - spokeAngle / 2.0;
    float spoke = smoothstep(-spokeWidth, 0.0, spokePattern) - smoothstep(0.0, spokeWidth, spokePattern);
    float centerGlow = exp(-radius * 20.0);
    vec4 texColor = texture(samp, uv * 0.5 + 0.5);
    float glow = max(spoke, centerGlow);
    
    color = texColor * vec4(glow, glow, glow, 1.0);
}
