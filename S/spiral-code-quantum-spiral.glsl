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
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.06, 0.39, 0.71)));
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p) + 0.001;
    vec3 accumulation = vec3(0.0);
    float weightSum = 0.0;

    for (int i = 0; i < 5; i++) {
        float level = float(i);
        float scale = exp2(level * 0.36);
        float phase = log(radius + 0.025) * (2.5 + level * 0.55) - time_f * (0.12 + level * 0.025);
        vec2 q = rotation(phase + level * 1.17) * p * scale;
        q += sin(q.yx * (7.0 + level * 2.0) + vec2(time_f, -time_f)) * 0.018;
        vec2 uv = mirrorUV(0.5 + q / vec2(aspect, 1.0));
        float weight = exp(-level * 0.42);
        accumulation += texture(samp, uv).rgb * palette(level * 0.12 + radius) * weight;
        weightSum += weight;
    }

    vec3 result = accumulation / max(weightSum, 0.001);
    float interference = pow(0.5 + 0.5 * sin(log(radius) * 31.0 + atan(p.y, p.x) * 9.0), 16.0);
    result += palette(radius - time_f * 0.03) * interference * 0.18;
    color = vec4(result, texture(samp, tc).a);
}
