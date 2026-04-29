#version 330 core
// Metal lattice — faint moving grid lattice overlay.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * iResolution / 24.0 + vec2(time_f * 0.05, 0.0);
    vec2 g = abs(fract(p) - 0.5);
    float line = min(g.x, g.y);
    float lattice = smoothstep(0.08, 0.0, line) * 0.45;
    color = vec4(c + vec3(0.4, 0.75, 1.05) * lattice, 1.0);
}
