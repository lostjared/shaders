#version 330 core
// GBA LCD-style color compression: slightly washed, gamma-lifted, mild blue cast.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    mat3 m = mat3(0.80, 0.10, 0.10,
                  0.10, 0.82, 0.08,
                  0.12, 0.12, 0.82);
    c = m * c;
    c = pow(c, vec3(1.0 / 1.45));
    c = mix(c, c * vec3(0.96, 0.99, 1.04), 0.5);
    color = vec4(c, 1.0);
}
