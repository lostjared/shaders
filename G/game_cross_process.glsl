#version 330 core
// Cross-process: cyan shadows + yellow highlights, classic indie-film grade.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 sh = c + vec3(-0.05, 0.02, 0.10) * (1.0 - lum);
    vec3 hi = sh + vec3(0.10, 0.08, -0.06) * lum;
    hi = (hi - 0.5) * 1.12 + 0.5;
    color = vec4(clamp(hi, 0.0, 1.0), 1.0);
}
