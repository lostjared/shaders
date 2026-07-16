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
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.02, 0.28, 0.62)));
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float angle = atan(p.y, p.x);
    float twist = log(radius + 0.035) * 4.2 - time_f * 0.65;
    float spiral = angle + twist;

    vec2 q = rotation(twist) * p;
    vec2 uv = mirrorUV(0.5 + q / vec2(aspect, 1.0));
    vec3 source = texture(samp, uv).rgb;

    float arms = pow(0.5 + 0.5 * sin(spiral * 3.0 - radius * 8.0), 6.0);
    float dust = pow(0.5 + 0.5 * sin(spiral * 11.0 + radius * 70.0), 20.0);
    vec3 glow = palette(radius * 1.7 - time_f * 0.08) * (arms * 0.25 + dust * 0.15);
    float core = exp(-radius * 9.0);
    vec3 result = source * (0.90 + arms * 0.12) + glow + palette(time_f * 0.05) * core * 0.35;
    color = vec4(result, texture(samp, tc).a);
}
