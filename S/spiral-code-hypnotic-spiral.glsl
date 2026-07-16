#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

const float TAU = 6.28318530718;

mat2 rotation(float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return mat2(cosine, -sine, sine, cosine);
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p) + 0.001;
    float angle = atan(p.y, p.x);
    float spiralA = angle * 6.0 + log(radius + 0.025) * 24.0 - time_f * 2.2;
    float spiralB = angle * 7.0 - log(radius + 0.025) * 21.0 + time_f * 1.7;
    float moire = sin(spiralA) * sin(spiralB);
    float warp = moire * 0.08 + sin(radius * 55.0 - time_f) * 0.025;
    float sampleTwist = log(radius + 0.04) * 2.8 + warp;
    vec2 q = rotation(sampleTwist) * p;
    vec3 source = texture(samp, mirrorUV(0.5 + q / vec2(aspect, 1.0))).rgb;

    float line = pow(abs(moire), 9.0);
    vec3 result = mix(source, source * palette(moire + radius), 0.28);
    result += palette(angle / TAU + time_f * 0.025) * line * 0.18;
    color = vec4(result, texture(samp, tc).a);
}
