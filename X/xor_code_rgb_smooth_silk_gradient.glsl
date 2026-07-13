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
    return 0.56 + 0.44 * cos(6.2831853 * (t + vec3(0.00, 0.27, 0.61)));
}

vec3 gaussian13(vec2 uv) {
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
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
    vec3 smoothColor = gaussian13(tc);
    float luminance = dot(smoothColor, vec3(0.299, 0.587, 0.114));
    float phase = 2.0 + 1.5 * sin(time_f * 0.22) + luminance * 2.0;
    float phaseLow = floor(phase * 8.0) / 8.0;
    float phaseMix = smoothstep(0.0, 1.0, fract(phase * 8.0));

    vec3 xorA = xorColor(smoothColor, smoothColor * phaseLow);
    vec3 xorB = xorColor(smoothColor, smoothColor * (phaseLow + 0.125));
    vec3 smoothXor = mix(xorA, xorB, phaseMix);
    vec3 gradient = palette(luminance * 0.75 + tc.x * 0.2 + time_f * 0.018);

    vec3 result = mix(smoothColor, smoothXor, 0.38);
    result = mix(result, result * gradient * 1.25, 0.32);
    result = smoothstep(vec3(0.0), vec3(1.0), result);
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
