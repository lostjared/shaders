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

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    local = local * local * (3.0 - 2.0 * local);
    return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), local.x),
               mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), local.x), local.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    value += noise(p) * 0.57;
    p = p * 2.03 + 4.7;
    value += noise(p) * 0.28;
    p = p * 2.07 + 8.2;
    return value + noise(p) * 0.15;
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
    float cloud = fbm(p * 6.0 + vec2(time_f * 0.08, -time_f * 0.05));
    float twist = log(radius + 0.04) * (3.4 + cloud) - time_f * 0.38;
    float spiral = angle + twist;
    vec2 q = rotation(twist) * p;
    vec3 source = texture(samp, mirrorUV(0.5 + q / vec2(aspect, 1.0))).rgb;

    float arms = pow(0.5 + 0.5 * sin(spiral * 4.0 + cloud * 4.0), 4.0);
    vec3 gas = 0.5 + 0.5 * cos(TAU * (cloud + radius + vec3(0.05, 0.32, 0.67)));
    vec3 result = mix(source, source * gas * 1.25, arms * 0.28);
    result += gas * arms * cloud * 0.16 + gas * exp(-radius * 8.0) * 0.28;
    color = vec4(result, texture(samp, tc).a);
}
