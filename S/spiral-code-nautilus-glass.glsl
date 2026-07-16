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

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p) + 0.0001;
    float angle = atan(p.y, p.x);

    float shell = angle / TAU + log(radius + 0.06) * 0.72 - time_f * 0.055;
    float chamber = fract(shell * 12.0);
    float ridge = 1.0 - smoothstep(0.0, 0.12, abs(chamber - 0.5));
    float bend = sin(shell * TAU * 2.0) * 0.16 + ridge * 0.05;
    vec2 q = rotation(bend) * p;
    vec2 uv = mirrorUV(0.5 + q / vec2(aspect, 1.0));

    vec3 source = texture(samp, uv).rgb;
    vec3 normal = normalize(vec3(-cos(shell * TAU) * 0.45, -sin(shell * TAU) * 0.45, 1.0));
    float specular = pow(max(dot(normal, normalize(vec3(-0.4, 0.6, 1.0))), 0.0), 28.0);
    vec3 result = source * vec3(0.94, 1.00, 1.04);
    result += vec3(0.16, 0.25, 0.27) * ridge + vec3(0.85, 0.94, 1.0) * specular * 0.32;
    color = vec4(result, texture(samp, tc).a);
}
