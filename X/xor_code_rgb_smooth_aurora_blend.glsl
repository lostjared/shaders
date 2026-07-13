#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

uvec3 bytes(vec3 c) {
    return uvec3(clamp(floor(c * 255.0 + 0.5), 0.0, 255.0));
}

vec3 xorColor(vec3 a, vec3 b) {
    return vec3((bytes(a) ^ bytes(b)) & uvec3(255u)) / 255.0;
}

vec3 palette(float t) {
    return 0.52 + 0.48 * cos(6.2831853 * (t + vec3(0.08, 0.40, 0.74)));
}

vec3 softFilter(vec2 uv) {
    vec2 px = 1.4 / max(iResolution, vec2(1.0));
    vec3 sum = texture(samp, uv).rgb * 4.0;
    sum += texture(samp, uv + vec2(px.x, 0.0)).rgb * 2.0;
    sum += texture(samp, uv - vec2(px.x, 0.0)).rgb * 2.0;
    sum += texture(samp, uv + vec2(0.0, px.y)).rgb * 2.0;
    sum += texture(samp, uv - vec2(0.0, px.y)).rgb * 2.0;
    return sum / 12.0;
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float curtain = sin(p.x * 5.0 + time_f * 0.55 + sin(p.y * 3.0 - time_f * 0.3) * 2.0);
    curtain += 0.35 * sin(p.x * 11.0 - time_f + p.y * 4.0);
    vec2 flow = vec2(curtain * 0.008, sin(p.x * 4.0 + time_f * 0.4) * 0.006);

    vec3 base = softFilter(tc + flow);
    vec3 neighbor = softFilter(tc - flow * 0.65).gbr;
    float key = 1.4 + 0.6 * sin(time_f * 0.18) + curtain * 0.16;
    vec3 bits = xorColor(base, neighbor * key);
    vec3 aurora = palette(p.y * 0.18 + curtain * 0.12 + time_f * 0.02);

    float veil = smoothstep(-0.8, 0.9, curtain);
    vec3 result = mix(base, bits, 0.24 + veil * 0.24);
    result = mix(result, sqrt(max(result, 0.0)) * aurora, 0.28 + veil * 0.16);
    result += aurora * pow(max(curtain, 0.0), 7.0) * 0.12;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
