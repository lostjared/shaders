#version 330 core
// Toxic / radiation green wash with subtle vignette pulse.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(c, vec3(lum) * vec3(0.55, 1.00, 0.55), 0.45);
    vec2 v = tc - 0.5;
    float pulse = 0.5 + 0.5 * sin(time_f * 1.5);
    c *= mix(0.7, 1.0, smoothstep(0.55, 0.05, dot(v, v) * (1.0 + 0.15 * pulse)));
    color = vec4(c, 1.0);
}
