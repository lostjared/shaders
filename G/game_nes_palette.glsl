#version 330 core
// NES-style 64-color palette quantization.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    c = floor(c * 4.0 + 0.5) / 4.0;
    c = pow(c, vec3(0.95));
    color = vec4(c, 1.0);
}
