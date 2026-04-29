#version 330 core
// Ice ripple — cool blue tint with soft expanding ripple highlights.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float r = length(p);
    float ripple = sin(r * 30.0 - time_f * 1.6);
    ripple = smoothstep(0.7, 1.0, ripple) * smoothstep(0.6, 0.0, r) * 0.55;
    vec3 ice = mix(c, c * vec3(0.78, 0.95, 1.20), 0.55);
    color = vec4(ice + vec3(0.7, 0.9, 1.0) * ripple, 1.0);
}
