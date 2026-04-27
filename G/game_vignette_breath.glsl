#version 330 core
// Slowly breathing vignette - emphasizes screen center, very gentle.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 v = tc - 0.5;
    float r = dot(v, v);
    float breath = 1.05 + 0.10 * sin(time_f * 0.6);
    float vig = smoothstep(0.85, 0.10, r * breath);
    c *= mix(0.55, 1.0, vig);
    color = vec4(c, 1.0);
}
