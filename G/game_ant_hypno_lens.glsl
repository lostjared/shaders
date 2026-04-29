#version 330 core
// Hypno lens — very mild radial barrel + brightness ring (gameplay-safe).
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 p = tc - 0.5;
    float r = length(p);
    float k = 1.0 + 0.14 * r * r;
    vec2 uv = p / k + 0.5;
    vec3 c = texture(samp, uv).rgb;
    float ring = sin(r * 22.0 - time_f * 0.8) * 0.5 + 0.5;
    ring = smoothstep(0.65, 1.0, ring) * smoothstep(0.6, 0.1, r);
    c += vec3(0.7, 0.55, 1.10) * ring * 0.45;
    color = vec4(c, 1.0);
}
