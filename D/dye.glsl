#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

void main(void) {
    vec2 p = tc - 0.5;
    float radius = length(p);
    float angle = atan(p.y, p.x);
    float flow = sin(angle * 5.0 - radius * 24.0 + time_f * 1.4);
    vec2 tangent = vec2(-p.y, p.x) / max(radius, 0.001);
    vec2 warped = tc + tangent * flow * 0.018;
    vec4 source = texture(samp, warped);
    vec3 dye = 0.55 + 0.45 * cos(vec3(0.0, 2.1, 4.2) + flow + time_f * 0.25);
    color = vec4(mix(source.rgb, source.rgb * dye * 1.7, 0.55), source.a);
}
