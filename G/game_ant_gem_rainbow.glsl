#version 330 core
// Gem rainbow — gentle rainbow saturation boost based on hue, very mild.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 sat = mix(vec3(lum), c, 1.45);
    float h = lum + time_f * 0.05;
    vec3 rainbow = 0.5 + 0.5 * cos(6.28318 * (h + vec3(0.0, 0.33, 0.67)));
    color = vec4(mix(sat, sat * (0.65 + 0.85 * rainbow), 0.70), 1.0);
}
