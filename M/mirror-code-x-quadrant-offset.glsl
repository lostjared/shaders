#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;

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
