#version 330 core
// HDR-style contrast and saturation lift. Makes dull SDR games pop.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec3 mapped = c / (c + vec3(0.18));
    mapped = mapped * 1.18;
    float lum = dot(mapped, vec3(0.299, 0.587, 0.114));
    mapped = mix(vec3(lum), mapped, 1.20);
    mapped = pow(clamp(mapped, 0.0, 1.0), vec3(0.93));
    color = vec4(mapped, 1.0);
}
