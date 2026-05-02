#version 330 core
// Hollywood teal-and-orange grade with mild contrast lift.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    c = (c - 0.5) * 1.12 + 0.5;
    vec3 shadows = mix(c, c * vec3(0.85, 1.00, 1.15), smoothstep(0.4, 0.0, dot(c, vec3(0.333))));
    vec3 highs = mix(shadows, shadows * vec3(1.18, 1.05, 0.85), smoothstep(0.5, 1.0, dot(c, vec3(0.333))));
    color = vec4(clamp(highs, 0.0, 1.0), 1.0);
}
