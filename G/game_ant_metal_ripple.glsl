#version 330 core
// Metal ripple — concentric ripple sheen from center, very subtle.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float r = length(p);
    float ring = sin(r * 38.0 - time_f * 1.2) * 0.5 + 0.5;
    ring = smoothstep(0.65, 1.0, ring) * smoothstep(0.7, 0.05, r) * 0.45;
    color = vec4(c + vec3(0.95, 0.97, 1.10) * ring, 1.0);
}
