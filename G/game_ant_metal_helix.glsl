#version 330 core
// Metal helix — twin spiral sheen lines around screen, faint.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float a = atan(p.y, p.x);
    float r = length(p);
    float h1 = sin(a * 2.0 + r * 18.0 - time_f * 0.5);
    float h2 = sin(a * 2.0 + r * 18.0 - time_f * 0.5 + 3.14159);
    float helix = max(smoothstep(0.85, 1.0, h1), smoothstep(0.85, 1.0, h2));
    color = vec4(c + vec3(0.85, 0.92, 1.10) * helix * 0.50, 1.0);
}
