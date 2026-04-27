#version 330 core
// Low-HP heartbeat: red vignette pulses with a thump-thump rhythm.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float beat(float t) {
    float p = mod(t, 1.0);
    float a = exp(-pow((p - 0.10) * 8.0, 2.0));
    float b = exp(-pow((p - 0.28) * 8.0, 2.0)) * 0.7;
    return a + b;
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float r = length(tc - 0.5);
    float vig = smoothstep(0.20, 0.85, r);
    float h = beat(time_f * 0.9);
    vec3 red = vec3(0.95, 0.05, 0.05);
    c = mix(c, c * 0.7 + red, vig * h * 0.85);
    float pulse = 1.0 + 0.04 * h;
    c *= pulse;
    color = vec4(c, 1.0);
}
