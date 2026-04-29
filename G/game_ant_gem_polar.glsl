#version 330 core
// Gem polar — slight polar-coordinate sheen rotating slowly (no warp).
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float a = atan(p.y, p.x) + time_f * 0.3;
    float r = length(p);
    float spoke = sin(a * 5.0) * 0.5 + 0.5;
    float mask = smoothstep(0.7, 0.0, r);
    vec3 tint = mix(vec3(0.65, 0.40, 1.10), vec3(0.30, 0.95, 1.10), spoke);
    color = vec4(c + tint * mask * 0.40, 1.0);
}
