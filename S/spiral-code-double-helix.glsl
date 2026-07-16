#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

mat2 rotation(float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return mat2(cosine, -sine, sine, cosine);
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float angle = atan(p.y, p.x);

    float twistA = log(radius + 0.025) * 3.8 - time_f * 0.75;
    float twistB = -log(radius + 0.025) * 3.8 + time_f * 0.58;
    float phaseA = angle + twistA;
    float phaseB = angle + twistB;
    vec2 uvA = mirrorUV(0.5 + rotation(twistA) * p / vec2(aspect, 1.0));
    vec2 uvB = mirrorUV(0.5 + rotation(twistB) * p / vec2(aspect, 1.0));
    vec3 a = texture(samp, uvA).rgb;
    vec3 b = texture(samp, uvB).rgb;

    float strandA = pow(0.5 + 0.5 * sin(phaseA * 2.0), 10.0);
    float strandB = pow(0.5 + 0.5 * sin(phaseB * 2.0), 10.0);
    float bridge = pow(0.5 + 0.5 * cos((phaseA - phaseB) * 2.0), 18.0);
    vec3 result = mix(a, b, 0.5 + 0.25 * sin(radius * 26.0 - time_f));
    result += vec3(0.20, 0.35, 0.48) * strandA * 0.28;
    result += vec3(0.48, 0.22, 0.38) * strandB * 0.28 + vec3(0.18) * bridge;
    color = vec4(result, texture(samp, tc).a);
}
