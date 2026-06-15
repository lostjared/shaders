#version 330 core
// Shadow realm: dark desaturated phase with violet highlights.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 p = tc - 0.5;
    float wave = sin((p.x * p.y) * 120.0 + time_f * 2.0) * 0.008;
    vec3 c = texture(samp, clamp(tc + vec2(wave, -wave), 0.0, 1.0)).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float pulse = 0.5 + 0.5 * sin(time_f * 1.5);
    c = mix(c, vec3(lum) * vec3(0.55, 0.45, 0.8), 0.75);
    c *= 0.55 + 0.25 * pulse;
    c += vec3(0.18, 0.0, 0.35) * smoothstep(0.05, 0.35, dot(p, p));
    color = vec4(c, 1.0);
}
