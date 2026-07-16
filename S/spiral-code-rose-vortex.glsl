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

vec3 rosePalette(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.00, 0.12, 0.30)));
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float twist = log(radius + 0.045) * 2.6 - time_f * 0.18;
    float spiral = atan(p.y, p.x) + twist;
    float petals = 0.78 + 0.22 * cos(spiral * 7.0 - radius * 18.0);
    float folds = 0.92 + 0.08 * sin(spiral * 14.0 + radius * 35.0);
    vec2 q = rotation(twist) * p * petals * folds;
    vec3 source = texture(samp, mirrorUV(0.5 + q / vec2(aspect, 1.0))).rgb;

    float edge = pow(0.5 + 0.5 * cos(spiral * 7.0 - radius * 18.0), 10.0);
    float center = exp(-radius * 12.0);
    vec3 result = mix(source, source * rosePalette(radius * 1.2), 0.26);
    result += rosePalette(spiral / TAU) * edge * 0.19 + vec3(0.35, 0.12, 0.18) * center;
    color = vec4(result, texture(samp, tc).a);
}
