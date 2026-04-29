#version 330 core
// Frac cosine — gentle cosine-palette tint based on luminance.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float t = lum + time_f * 0.05;
    vec3 pal = 0.5 + 0.5 * cos(6.28318 * t + vec3(0.0, 0.45, 0.95));
    color = vec4(mix(c, c * pal * 1.8, 0.55), 1.0);
}
