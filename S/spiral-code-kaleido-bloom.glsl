#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

const float TAU = 6.28318530718;

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec3 palette(float t) {
    return 0.55 + 0.45 * cos(TAU * (t + vec3(0.00, 0.18, 0.48)));
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float angle = atan(p.y, p.x) + log(radius + 0.04) * 2.8 - time_f * 0.42;
    float slice = TAU / 10.0;
    angle = abs(mod(angle + slice * 0.5, slice) - slice * 0.5);

    float petal = 0.78 + 0.22 * cos(angle * 10.0 - radius * 14.0);
    vec2 q = vec2(cos(angle), sin(angle)) * radius * petal;
    vec3 source = texture(samp, mirrorUV(0.5 + q / vec2(aspect, 1.0))).rgb;
    float edge = pow(0.5 + 0.5 * cos(angle * 10.0 - radius * 20.0), 14.0);
    vec3 result = mix(source, source * palette(radius * 1.3 + time_f * 0.04), 0.32);
    result += palette(angle / slice + radius) * edge * 0.18;
    color = vec4(result, texture(samp, tc).a);
}
