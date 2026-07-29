#version 330 core
// Low-battery handheld: dim, slight green-yellow shift, occasional flicker.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float t = floor(time_f * 12.0);
    float flicker = 0.85 + 0.15 * hash(t);
    if (hash(t * 0.3) > 0.96) flicker *= 0.4;
    c *= flicker;
    c *= vec3(0.95, 1.0, 0.78);
    float vig = smoothstep(1.0, 0.5, length(tc - 0.5));
    color = vec4(c * vig * 0.85, 1.0);
}
