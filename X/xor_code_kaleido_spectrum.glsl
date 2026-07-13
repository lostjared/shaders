#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

const float TAU = 6.28318530718;

uvec3 bytes(vec3 c) {
    return uvec3(clamp(floor(c * 255.0 + 0.5), 0.0, 255.0));
}

vec3 xorColor(vec3 a, vec3 b) {
    return vec3((bytes(a) ^ bytes(b)) & uvec3(255u)) / 255.0;
}

vec3 spectrum(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.00, 0.33, 0.67)));
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float radius = length(p);
    float angle = atan(p.y, p.x) + time_f * 0.28 + radius * 2.5;
    float wedge = TAU / 10.0;
    float folded = abs(mod(angle + wedge * 0.5, wedge) - wedge * 0.5);
    folded += sin(radius * 35.0 - time_f * 3.0) * 0.05;

    vec2 kaleido = vec2(cos(folded), sin(folded)) * radius / ar + 0.5;
    vec3 original = texture(samp, tc).rgb;
    vec3 reflected = texture(samp, kaleido).rgb;
    vec3 rotated = texture(samp, 1.0 - kaleido.yx).gbr;
    vec3 bits = xorColor(reflected, rotated * (1.5 + radius));

    vec3 tint = spectrum(folded / wedge + radius * 0.7 + time_f * 0.025);
    float facet = pow(abs(cos(folded * 10.0)), 8.0);
    vec3 result = mix(original, bits, 0.58);
    result = mix(result, result * tint * 1.45, 0.4);
    result += tint * facet * 0.28;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, kaleido).a);
}
