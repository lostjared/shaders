#version 330 core
// Gem spectrum — drifting hue spectrum tint over the frame.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float h = tc.x + time_f * 0.04;
    vec3 spec = 0.5 + 0.5 * cos(6.28318 * (h + vec3(0.0, 0.33, 0.67)));
    color = vec4(mix(c, c * (0.5 + 1.0 * spec), 0.55), 1.0);
}
