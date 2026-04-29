#version 330 core
// Metal prism — gentle RGB chromatic split on edges of bright objects.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 p = tc - 0.5;
    float r = length(p);
    vec2 dir = p / max(r, 1e-4);
    float k = 0.0090 * smoothstep(0.0, 0.7, r);
    float rC = texture(samp, tc + dir * k).r;
    float gC = texture(samp, tc).g;
    float bC = texture(samp, tc - dir * k).b;
    color = vec4(rC, gC, bC, 1.0);
}
