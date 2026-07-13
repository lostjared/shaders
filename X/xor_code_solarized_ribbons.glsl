#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

uvec3 bytes(vec3 c) {
    return uvec3(clamp(floor(c * 255.0 + 0.5), 0.0, 255.0));
}

vec3 fromBytes(uvec3 c) {
    return vec3(c & uvec3(255u)) / 255.0;
}

vec3 palette(float t) {
    return 0.54 + 0.46 * cos(6.2831853 * (t + vec3(0.04, 0.30, 0.61)));
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float ribbonA = sin(p.y * 15.0 + sin(p.x * 5.0 - time_f) * 3.0 + time_f * 2.0);
    float ribbonB = cos(p.x * 17.0 + sin(p.y * 7.0 + time_f) * 2.5 - time_f * 1.7);
    float ribbons = ribbonA * ribbonB;
    vec2 flow = vec2(ribbonA, ribbonB) * 0.018;

    vec3 base = texture(samp, tc + flow).rgb;
    uvec3 src = bytes(base);
    uvec3 inverted = uvec3(255u) - src;
    uvec3 ribbonMask =
        uvec3(uint((ribbonA * 0.5 + 0.5) * 255.0), uint((ribbonB * 0.5 + 0.5) * 255.0),
              uint((ribbons * 0.5 + 0.5) * 255.0));
    vec3 solar = fromBytes((src ^ ribbonMask) ^ (inverted >> uvec3(1u, 2u, 3u)));

    vec3 tint = palette(ribbons * 0.22 + p.x * 0.08 + time_f * 0.03);
    float crest = pow(abs(ribbons), 7.0);
    vec3 result = mix(base, solar, 0.48 + 0.22 * abs(ribbons));
    result = mix(result, result * tint * 1.35, 0.36);
    result += tint * crest * 0.35;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
