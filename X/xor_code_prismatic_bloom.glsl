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
    return 0.52 + 0.48 * cos(6.2831853 * (t + vec3(0.00, 0.31, 0.67)));
}

vec3 softBloom(vec2 uv) {
    vec2 px = 1.5 / max(iResolution, vec2(1.0));
    vec3 sum = texture(samp, uv).rgb * 4.0;
    sum += texture(samp, uv + vec2(px.x, 0.0)).rgb * 2.0;
    sum += texture(samp, uv - vec2(px.x, 0.0)).rgb * 2.0;
    sum += texture(samp, uv + vec2(0.0, px.y)).rgb * 2.0;
    sum += texture(samp, uv - vec2(0.0, px.y)).rgb * 2.0;
    sum += texture(samp, uv + px).rgb;
    sum += texture(samp, uv - px).rgb;
    sum += texture(samp, uv + vec2(px.x, -px.y)).rgb;
    sum += texture(samp, uv + vec2(-px.x, px.y)).rgb;
    return sum / 16.0;
}

void main(void) {
    vec2 p = tc - 0.5;
    float radius = length(p);
    float angle = atan(p.y, p.x);
    float wave = sin(radius * 42.0 - time_f * 4.0 + angle * 6.0);
    vec2 split = normalize(p + vec2(0.0001)) * (0.002 + 0.006 * wave);

    vec3 prism =
        vec3(texture(samp, tc + split).r, texture(samp, tc).g, texture(samp, tc - split).b);
    vec3 bloom = softBloom(tc);
    vec3 key = palette(radius * 1.8 + angle / 6.2831853 + time_f * 0.04);
    vec3 bits = xorColor(prism, bloom * (1.8 + 0.7 * wave) + key * 0.35);

    float halo = pow(0.5 + 0.5 * wave, 6.0);
    vec3 result = mix(prism, bits, 0.42 + 0.28 * halo);
    result = 1.0 - (1.0 - result) * (1.0 - key * halo * 0.55);
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
