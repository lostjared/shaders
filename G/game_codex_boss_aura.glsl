#version 330 core
// Boss aura: hostile purple vignette and rotating radial pressure waves.
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
    float rays = pow(0.5 + 0.5 * sin(a * 9.0 + r * 18.0 - time_f * 3.0), 5.0);
    float edge = smoothstep(0.12, 0.58, r);
    vec3 c = texture(samp, tc).rgb;
    vec3 aura = vec3(0.7, 0.05, 1.0) * (edge * 0.55 + rays * 0.28);
    c = mix(c, c * vec3(0.85, 0.65, 1.05), edge * 0.45) + aura;
    color = vec4(c, 1.0);
}
