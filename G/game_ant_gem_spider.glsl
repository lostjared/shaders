#version 330 core
// Gem spider — faint radial spider-web overlay.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float a = atan(p.y, p.x);
    float r = length(p);
    float spoke = abs(sin(a * 6.0));
    float ring = abs(sin(r * 24.0));
    float web = max(smoothstep(0.88, 1.0, 1.0 - spoke), smoothstep(0.88, 1.0, 1.0 - ring));
    color = vec4(c - vec3(web) * 0.45, 1.0);
}
