#version 330 core
// Metal opal — iridescent rainbow shift on bright pixels (oil-slick look).
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float h = lum + tc.x * 0.2 + tc.y * 0.15 + time_f * 0.05;
    vec3 opal = 0.5 + 0.5 * cos(6.28318 * (h + vec3(0.0, 0.33, 0.67)));
    float mask = smoothstep(0.30, 0.85, lum);
    color = vec4(mix(c, c * (0.5 + 1.1 * opal), mask * 0.75), 1.0);
}
