#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

const float TAU = 6.28318530718;

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x) + time_f * 0.65 + 1.15 / r;
    float wedge = TAU / 12.0;
    a = abs(mod(a + wedge * 0.5, wedge) - wedge * 0.5);
    a += sin(r * 60.0 - time_f * 11.0) * 0.24;
    float depth = fract(-log(r) * 0.68 + time_f * 0.72);
    float rr = fract(r * 3.2 + depth + sin(a * 24.0) * 0.08);
    vec2 q = vec2(cos(a), sin(a)) * rr;
    vec2 uv = fract(q / ar + 0.5);
    vec2 uv2 = fract(vec2(a / wedge, depth + r * 2.0));
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, uv2);
    float facets = pow(abs(cos(a * 12.0)), 5.0);
    color = vec4(mix(c0.rgb, c1.bgr, 0.36) * (0.72 + facets * 0.58), c0.a);
}
