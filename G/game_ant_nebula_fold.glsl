#version 330 core
// Nebula fold — folded color washes drifting across, gentle.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p = abs(p);
    float n = sin(p.x * 6.0 + p.y * 4.0 + time_f * 0.25);
    n = n * 0.5 + 0.5;
    vec3 neb = mix(vec3(0.20, 0.55, 1.10), vec3(1.05, 0.30, 0.70), n);
    color = vec4(c + neb * 0.40, 1.0);
}
