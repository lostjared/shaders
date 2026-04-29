#version 330 core
// Aurora tunnel — soft northern-lights vignette around frame edges.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float r = length(p);
    float edge = smoothstep(0.20, 0.75, r);
    float wave = sin(atan(p.y, p.x) * 3.0 + time_f * 0.5) * 0.5 + 0.5;
    vec3 aurora = mix(vec3(0.10, 0.95, 0.55), vec3(0.55, 0.30, 1.05), wave);
    c = mix(c, c + aurora, edge * 0.55);
    color = vec4(c, 1.0);
}
