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

float hash11(float value) {
    return fract(sin(value * 127.1) * 43758.5453);
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p) + 0.001;
    float angle = atan(p.y, p.x);
    float twist = log(radius + 0.025) * 4.8 - time_f * 1.05;
    float spiral = angle + twist;
    vec2 q = rotation(twist) * p;
    vec3 source = texture(samp, mirrorUV(0.5 + q / vec2(aspect, 1.0))).rgb;

    float arcs = 0.0;
    for (int i = 0; i < 4; i++) {
        float index = float(i);
        float jitter = sin(radius * (72.0 + index * 13.0) - time_f * (3.0 + index));
        float line = abs(sin(spiral * (3.0 + index) + jitter * 0.22 + index * 1.7));
        arcs += pow(1.0 - line, 32.0) * (0.55 + hash11(index) * 0.45);
    }

    float pulse = 0.72 + 0.28 * sin(time_f * 7.0 + radius * 24.0);
    vec3 electric = mix(vec3(0.12, 0.28, 0.85), vec3(0.62, 0.92, 1.0), clamp(arcs, 0.0, 1.0));
    vec3 result = source * 0.84 + electric * arcs * pulse * 0.34;
    color = vec4(result, texture(samp, tc).a);
}
