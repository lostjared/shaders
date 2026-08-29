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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;

float mirrorRepeat(float value) {
    return 1.0 - abs(mod(value, 2.0) - 1.0);
}

void main() {
    vec2 quadrant = step(vec2(0.5), tc);
    vec2 offset = vec2(quadrant.y, quadrant.x) * 0.25;
    vec2 uv = vec2(mirrorRepeat(tc.x + offset.x),
                   mirrorRepeat(tc.y + offset.y));
    color = texture(samp, uv);
}
