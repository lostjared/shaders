#version 330 core
// Green phosphor terminal monitor.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    lum = pow(lum, 0.85);
    vec3 green = vec3(0.10, 1.00, 0.30) * lum;
    float scan = 0.88 + 0.12 * sin(gl_FragCoord.y * 1.5);
    color = vec4(green * scan, 1.0);
}
