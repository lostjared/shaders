#version 330 core
// Slow red pulse on the edges - "low health" feedback.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 v = tc - 0.5;
    float r = dot(v, v);
    float pulse = 0.5 + 0.5 * sin(time_f * 2.4);
    float edge = smoothstep(0.10, 0.32, r);
    vec3 red = vec3(0.85, 0.05, 0.05);
    c = mix(c, mix(c * 0.7, red, 0.55), edge * pulse);
    color = vec4(c, 1.0);
}
