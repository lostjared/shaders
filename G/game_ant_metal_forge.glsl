#version 330 core
// Metal forge — heated forge tint with slow ember pulse on bright pixels.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 forge = c * vec3(1.20, 0.92, 0.78);
    float pulse = 0.5 + 0.5 * sin(time_f * 0.9);
    float hot = smoothstep(0.40, 0.95, lum) * pulse;
    forge += vec3(1.0, 0.40, 0.10) * hot * 0.65;
    color = vec4(forge, 1.0);
}
