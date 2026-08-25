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
    vec2 uv = tc * iResolution / vec2(iResolution.y);
    vec2 center = vec2(0.5, 0.5) * iResolution / vec2(iResolution.y);
    vec2 pos = uv - center;
    float r = length(pos);
    float angle = atan(pos.y, pos.x);
    float numSegments = 6.0;
    float segmentAngle = 2.0 * 3.14159 / numSegments;
    angle = mod(angle, segmentAngle);
    angle = abs(angle - segmentAngle / 2.0);
    pos.x = r * cos(angle);
    pos.y = r * sin(angle);
    float rotationSpeed = time_f * 0.7;
    float cosA = cos(rotationSpeed);
    float sinA = sin(rotationSpeed);
    mat2 rot = mat2(cosA, -sinA, sinA, cosA);
    pos = rot * pos;
    vec4 texColor = texture(samp, pos + center);
    color = texColor;
}
