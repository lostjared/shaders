#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec2 rotate2(vec2 p, float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c) * p;
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.001;
    float baseTwist = time_f * 0.75 + 1.05 / r;
    vec3 sum = vec3(0.0);
    float weight = 0.0;
    for (int i = 0; i < 6; ++i) {
        float fi = float(i);
        float w = 1.0 - fi * 0.12;
        vec2 q = rotate2(p * (1.0 + fi * 0.085), baseTwist + fi * 0.42);
        q += normalize(q + vec2(0.0001)) * sin(r * (42.0 + fi * 8.0) - time_f * (8.0 + fi)) * 0.035;
        vec3 tap = texture(samp, fract(q / ar + 0.5)).rgb;
        sum += mix(tap, tap.bgr, fi / 10.0) * w;
        weight += w;
    }
    vec3 rgb = sum / weight;
    rgb *= 0.78 + 0.42 * sin(r * 64.0 - time_f * 11.0);
    color = vec4(rgb, texture(samp, tc).a);
}
