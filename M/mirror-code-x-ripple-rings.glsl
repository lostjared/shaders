#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform vec2 iResolution;

const float PI = 3.14159265359;

float mirrorRepeat(float value) {
    return 1.0 - abs(mod(value, 2.0) - 1.0);
}

void main() {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float foldedRadius = mirrorRepeat(radius * 8.0) / 8.0;
    p *= foldedRadius / max(radius, 0.0001);
    vec2 uv = p / vec2(aspect, 1.0) + 0.5;
    color = texture(samp, uv);
}
