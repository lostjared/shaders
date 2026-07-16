#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

const float TAU = 6.28318530718;

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

mat2 rotation(float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return mat2(cosine, -sine, sine, cosine);
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec3 flamePalette(float t) {
    return mix(vec3(0.35, 0.015, 0.005), vec3(1.0, 0.72, 0.16), clamp(t, 0.0, 1.0));
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float angle = atan(p.y, p.x);
    vec2 noisePoint = rotation(time_f * 0.08) * p * 11.0;
    noisePoint += normalize(p + vec2(0.0001)) * sin(radius * 17.0 - time_f * 0.8);
    float turbulence = noise(noisePoint);
    float twist = log(radius + 0.035) * (3.8 + turbulence) - time_f * 0.72;
    float spiral = angle + twist;
    vec2 q = rotation(twist) * p;
    q += normalize(q + vec2(0.0001)) * (turbulence - 0.5) * 0.025;
    vec3 source = texture(samp, mirrorUV(0.5 + q / vec2(aspect, 1.0))).rgb;

    float flame = pow(0.5 + 0.5 * sin(spiral * 5.0 + turbulence * 5.0), 5.0);
    flame *= 1.0 - smoothstep(0.08, 0.90, radius);
    vec3 result = source * mix(vec3(0.86, 0.72, 0.62), vec3(1.02), flame * 0.25);
    result += flamePalette(flame) * flame * 0.30;
    color = vec4(result, texture(samp, tc).a);
}
