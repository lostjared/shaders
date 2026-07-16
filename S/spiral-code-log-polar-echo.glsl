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
    return 0.56 + 0.44 * cos(TAU * (t + vec3(0.0, 0.31, 0.63)));
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p) + 0.002;
    float angle = atan(p.y, p.x);
    vec2 direction = p / radius;
    vec3 accumulation = vec3(0.0);
    float weightSum = 0.0;

    for (int i = 0; i < 6; i++) {
        float echo = float(i);
        float echoRadius = radius + echo * 0.018;
        float depth = fract(-log(echoRadius) * 0.52 + time_f * 0.12);
        float twist = log(echoRadius) * TAU * 0.62 - time_f * TAU * 0.07 + echo * TAU * 0.055;
        float sampleRadius = mix(0.06, 0.72, depth);
        vec2 echoPoint = rotation(twist) * direction * sampleRadius;
        vec2 uv = mirrorUV(0.5 + echoPoint / vec2(aspect, 1.0));
        float weight = exp(-echo * 0.34);
        accumulation += texture(samp, uv).rgb * palette(echo * 0.13 + radius) * weight;
        weightSum += weight;
    }

    vec3 result = accumulation / max(weightSum, 0.001);
    float echoLine = pow(0.5 + 0.5 * sin(angle * 4.0 + log(radius) * 17.0), 14.0);
    result += palette(radius - time_f * 0.04) * echoLine * 0.14;
    color = vec4(result, texture(samp, tc).a);
}
