#version 330 core
// Soft fog overlay - distance-y based mist using vertical gradient.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float fogAmt = smoothstep(0.2, 0.85, 1.0 - tc.y) * 0.35;
    vec3 fog = vec3(0.78, 0.82, 0.88);
    c = mix(c, fog, fogAmt);
    vec2 v = tc - 0.5;
    c *= mix(0.85, 1.0, smoothstep(0.6, 0.05, dot(v, v)));
    color = vec4(c, 1.0);
}
