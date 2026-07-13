#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

uvec3 bytes(vec3 c) {
    return uvec3(clamp(floor(c * 255.0 + 0.5), 0.0, 255.0));
}

vec3 fromBytes(uvec3 v) {
    return vec3(v & uvec3(255u)) / 255.0;
}

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.2831853 * (t + vec3(0.08, 0.38, 0.72)));
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float curtain = sin(p.x * 8.0 + time_f * 0.8 + sin(p.y * 4.0 - time_f) * 2.0);
    curtain += 0.5 * sin(p.x * 19.0 - time_f * 1.7 + p.y * 7.0);
    vec2 uv = tc + vec2(curtain * 0.012, sin(p.x * 5.0 + time_f) * 0.009);

    vec3 source = texture(samp, uv).rgb;
    uvec3 src = bytes(source);
    uint plane = uint(clamp(floor((curtain * 0.5 + 0.5) * 7.0), 0.0, 7.0));
    uint movingBit = 1u << plane;
    uvec3 spatial = uvec3(uint(tc.x * 255.0), uint(tc.y * 255.0),
                          uint(fract(tc.x + tc.y + time_f * 0.05) * 255.0));
    uvec3 manipulated = (src ^ spatial ^ uvec3(movingBit, movingBit << 1u, movingBit << 2u));
    vec3 bitColor = fromBytes(manipulated);

    vec3 aurora = palette(curtain * 0.18 + p.y * 0.22 + time_f * 0.025);
    float veil = smoothstep(-0.7, 0.8, curtain);
    vec3 result = mix(source, bitColor, 0.35 + 0.35 * veil);
    result = mix(result, result * aurora * 1.35, 0.28 + 0.25 * abs(curtain));
    result += aurora * pow(max(curtain, 0.0), 6.0) * 0.3;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, uv).a);
}
