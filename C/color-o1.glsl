#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(6.2831853 * (phase + vec3(0.0, 0.33, 0.67)));
}

void main(void) {
    vec4 source = texture(samp, tc);
    vec2 p = tc - 0.5;
    float orbit = atan(p.y, p.x) / 6.2831853;
    float rings = length(p) * 3.0;
    vec3 tint = palette(orbit + rings - time_f * 0.08);
    color = vec4(mix(source.rgb, source.rgb * tint * 1.8, 0.65), source.a);
}
