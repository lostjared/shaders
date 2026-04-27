#version 330 core
// Pulsing red boss-fight warning vignette with edge bands.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 v = tc - 0.5;
    float r = length(v);
    float pulse = 0.5 + 0.5 * sin(time_f * 6.0);
    float vig = smoothstep(0.25, 0.75, r);
    vec3 red = vec3(1.0, 0.05, 0.05);
    c = mix(c, c * 0.6 + red * 0.7, vig * (0.4 + 0.5 * pulse));
    float band = step(0.95, abs(tc.y - 0.5) * 2.0);
    c = mix(c, red, band * pulse * 0.9);
    color = vec4(c, 1.0);
}
