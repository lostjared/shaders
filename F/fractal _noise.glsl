#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
               mix(hash(cell + vec2(0.0, 1.0)), hash(cell + 1.0), f.x), f.y);
}

void main(void) {
    vec2 p = tc * 5.0;
    float value = 0.0;
    float weight = 0.5;
    for (int i = 0; i < 5; ++i) {
        value += weight * noise(p + time_f * vec2(0.07, -0.05));
        p = mat2(1.6, -1.2, 1.2, 1.6) * p;
        weight *= 0.5;
    }
    vec2 offset = vec2(dFdx(value), dFdy(value)) * 0.12;
    vec4 source = texture(samp, tc + offset);
    vec3 tint = 0.6 + 0.4 * cos(vec3(0.0, 2.0, 4.0) + value * 7.0);
    color = vec4(mix(source.rgb, source.rgb * tint * 1.6, 0.55), source.a);
}
