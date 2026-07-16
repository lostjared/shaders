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
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.08, 0.38, 0.70)));
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p) + 0.002;
    float angle = atan(p.y, p.x);
    float depth = fract(-log(radius) * 0.64 + time_f * 0.20);
    float twist = depth * TAU * 0.88 - time_f * TAU * 0.06;
    float tunnelRadius = mix(0.04, 0.74, depth);
    vec2 tunnelPoint = rotation(twist) * (p / radius) * tunnelRadius;
    vec2 uv = mirrorUV(0.5 + tunnelPoint / vec2(aspect, 1.0));
    vec3 source = texture(samp, uv).rgb;

    float throat = smoothstep(0.02, 0.22, radius);
    float ring = pow(0.5 + 0.5 * sin(depth * TAU * 8.0 + angle * 2.0), 14.0);
    float stream = pow(0.5 + 0.5 * sin(angle * 5.0 + log(radius) * 18.0), 8.0);
    vec3 result = source * (0.52 + 0.48 * throat);
    result += palette(depth + time_f * 0.025) * ring * stream * 0.24;
    result += palette(time_f * 0.04) * exp(-abs(radius - 0.20) * 38.0) * 0.15;
    color = vec4(result, texture(samp, tc).a);
}
