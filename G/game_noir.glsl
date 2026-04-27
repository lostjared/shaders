#version 330 core
// High-contrast film noir black & white.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.30, 0.62, 0.08));
    lum = (lum - 0.5) * 1.45 + 0.5;
    lum = clamp(lum, 0.0, 1.0);
    vec2 v = tc - 0.5;
    float vig = 1.0 - dot(v, v) * 1.4;
    color = vec4(vec3(lum) * vig, 1.0);
}
