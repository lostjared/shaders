#version 330 core
// Cool moody color grade for sci-fi / horror games.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    c = (c - 0.5) * 1.08 + 0.46;
    c *= vec3(0.88, 0.97, 1.08);
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(lum) * vec3(0.9, 1.0, 1.1), c, 0.78);
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
