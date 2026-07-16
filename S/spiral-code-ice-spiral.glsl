#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

const float PI = 3.14159265359;
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
    float radius = length(p);
    float baseAngle = atan(p.y, p.x);
    float twist = log(radius + 0.04) * 3.2 - time_f * 0.16;
    float angle = baseAngle + twist;
    float sector = TAU / 24.0;
    float sectorPhase = mod(angle + PI, sector);
    float facetOffset = sector * 0.5 - sectorPhase;
    float facetMix = 0.34 + 0.12 * sin(radius * 36.0 + cos(angle * 12.0) * 2.0);
    vec2 q = rotation(twist + facetOffset * facetMix) * p;
    vec2 uv = mirrorUV(0.5 + q / vec2(aspect, 1.0));
    vec3 source = texture(samp, uv).rgb;

    float frost = pow(0.5 + 0.5 * sin(angle * 12.0 - radius * 47.0), 18.0);
    float shard = pow(0.5 + 0.5 * cos(angle * 24.0), 22.0);
    vec3 result = source * vec3(0.78, 0.92, 1.08);
    result += vec3(0.56, 0.78, 0.92) * frost * 0.25 + vec3(0.35, 0.52, 0.68) * shard * 0.16;
    color = vec4(result, texture(samp, tc).a);
}
