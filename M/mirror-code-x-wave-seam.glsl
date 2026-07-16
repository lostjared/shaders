#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

float mirrorRepeat(float value) {
    return 1.0 - abs(mod(value, 2.0) - 1.0);
}

void main() {
    float seam = 0.5 + 0.12 * sin(tc.y * 12.0 + time_f);
    float foldedX = seam + abs(tc.x - seam);
    vec2 uv = vec2(mirrorRepeat(foldedX), tc.y);
    color = texture(samp, uv);
}
