#version 330 core
// Sepia + soft brown tint for old-timey feel.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 sep = vec3(lum) * vec3(1.05, 0.85, 0.65);
    sep = mix(c, sep, 0.85);
    vec2 v = tc - 0.5;
    sep *= mix(0.7, 1.0, smoothstep(0.6, 0.05, dot(v, v)));
    color = vec4(sep, 1.0);
}
