#version 330 core
// Frac smooth — smooth radial vignette + tonemap, calm cinematic look.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    c = c / (c + vec3(1.0));
    c = pow(c, vec3(0.85));
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float r = length(p);
    float vign = smoothstep(0.95, 0.10, r);
    color = vec4(c * (0.55 + 0.55 * vign), 1.0);
}
