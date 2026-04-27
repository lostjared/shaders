#version 330 core
// Hacker terminal: green phosphor monochrome, scanlines, occasional flicker.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    lum = pow(lum, 0.85);
    vec3 green = vec3(0.05, 1.0, 0.25) * lum;
    float scan = 0.85 + 0.15 * sin(tc.y * iResolution.y * 3.14159);
    float flick = 0.95 + 0.05 * hash(floor(time_f * 18.0));
    green *= scan * flick;
    float vig = smoothstep(0.95, 0.4, length(tc - 0.5));
    color = vec4(green * vig, 1.0);
}
