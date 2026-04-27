#version 330 core
// Amber monochrome monitor (vintage terminal).
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    lum = pow(lum, 0.85);
    vec3 amber = vec3(1.0, 0.65, 0.10) * lum;
    float scan = 0.88 + 0.12 * sin(gl_FragCoord.y * 1.5);
    color = vec4(amber * scan, 1.0);
}
