#version 330 core
// Radar ping: green sweep line and expanding detection rings.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float sweepA = time_f * 2.2;
    float sweep = 1.0 - smoothstep(0.0, 0.18, abs(atan(sin(a - sweepA), cos(a - sweepA))));
    float ring = smoothstep(0.015, 0.0, abs(r - mod(time_f * 0.22, 0.55)));
    vec3 c = texture(samp, tc).rgb * vec3(0.75, 1.0, 0.75);
    c += vec3(0.1, 1.0, 0.25) * (sweep * smoothstep(0.55, 0.02, r) + ring) * 0.65;
    color = vec4(c, 1.0);
}
