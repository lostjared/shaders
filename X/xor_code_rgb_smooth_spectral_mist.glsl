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
    return 0.55 + 0.45 * cos(6.2831853 * (t + vec3(0.06, 0.38, 0.71)));
}

vec3 crossBlur(vec2 uv, float radius) {
    vec2 px = radius / max(iResolution, vec2(1.0));
    vec3 sum = texture(samp, uv).rgb * 4.0;
    sum += texture(samp, uv + vec2(px.x, 0.0)).rgb;
    sum += texture(samp, uv - vec2(px.x, 0.0)).rgb;
    sum += texture(samp, uv + vec2(0.0, px.y)).rgb;
    sum += texture(samp, uv - vec2(0.0, px.y)).rgb;
    return sum / 8.0;
}

void main(void) {
    vec3 fine = crossBlur(tc, 1.5);
    vec3 medium = crossBlur(tc, 4.0);
    vec3 wide = crossBlur(tc, 9.0);
    float luminance = dot(medium, vec3(0.299, 0.587, 0.114));
    float mist = 0.5 + 0.5 * sin(tc.x * 4.0 + tc.y * 5.0 + time_f * 0.28);

    float phase = 1.6 + 0.5 * sin(time_f * 0.16);
    vec3 lowBits = xorColor(medium, wide * phase);
    vec3 highBits = xorColor(fine, medium * (phase + 0.35));
    vec3 blendedBits = mix(lowBits, highBits, smoothstep(0.2, 0.8, luminance));
    vec3 tint = palette(luminance * 0.7 + mist * 0.2 + time_f * 0.014);

    vec3 result = mix(fine, blendedBits, 0.25 + mist * 0.16);
    result = mix(result, sqrt(max(result, 0.0)) * tint, 0.32);
    result = mix(result, wide * tint, 0.12);
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
