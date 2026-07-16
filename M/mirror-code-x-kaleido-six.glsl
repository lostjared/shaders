#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform vec2 iResolution;

const float PI = 3.14159265359;

void main() {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float sector = 2.0 * PI / 6.0;
    float angle = abs(mod(atan(p.y, p.x) + 0.5 * sector, sector) - 0.5 * sector);
    p = radius * vec2(cos(angle), sin(angle));
    vec2 uv = p / vec2(aspect, 1.0) + 0.5;
    color = texture(samp, uv);
}
