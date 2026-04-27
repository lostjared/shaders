#version 330 core
// Polaroid look - lifted blacks, faded highlights, warm cast.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    c = c * 0.85 + 0.10;
    c *= vec3(1.06, 1.00, 0.92);
    c = mix(c, vec3(dot(c, vec3(0.3, 0.6, 0.1))), 0.10);
    vec2 v = tc - 0.5;
    c *= mix(0.85, 1.0, smoothstep(0.5, 0.0, dot(v, v)));
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
