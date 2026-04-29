#version 330 core
// Liquid mirror — soft horizontal sheen band scrolls down the frame.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float band = fract(tc.y - time_f * 0.08);
    float sheen = smoothstep(0.42, 0.50, band) * smoothstep(0.58, 0.50, band);
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 mir = mix(c, c * 0.85 + vec3(lum) * 0.45, 0.55);
    color = vec4(mir + sheen * vec3(0.85, 0.92, 1.0) * 0.85, 1.0);
}
