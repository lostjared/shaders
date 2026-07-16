#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

float mirrorRepeat(float value) {
    return 1.0 - abs(mod(value, 2.0) - 1.0);
}

void main() {
    float axis = 0.5 + 0.25 * sin(time_f * 0.7);
    float distanceToAxis = abs(tc.x - axis);
    vec2 uv = vec2(mirrorRepeat(axis + distanceToAxis), tc.y);
    color = texture(samp, uv);
}
