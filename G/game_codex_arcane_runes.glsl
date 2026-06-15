#version 330 core
// Arcane runes: rotating sigils over the screen for spell-cast feedback.
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
    float sigil = step(0.93, sin(a * 12.0 - time_f * 2.4) * 0.5 + 0.5);
    sigil *= smoothstep(0.015, 0.0, abs(r - 0.32));
    float inner = smoothstep(0.01, 0.0, abs(fract((a + time_f) * 2.0) - 0.5) - 0.47) * smoothstep(0.28, 0.05, r);
    vec3 c = texture(samp, tc).rgb;
    c += vec3(0.75, 0.22, 1.0) * min(1.0, sigil + inner) * 0.85;
    color = vec4(c, 1.0);
}
