#version 330 core
// Fractal ocean — soft blue tint with slow undulating wave bands.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * 4.0;
    float w = sin(p.x + time_f * 0.4) * 0.5 + sin(p.y * 1.3 + time_f * 0.3) * 0.5;
    w = w * 0.5 + 0.5;
    vec3 ocean = mix(vec3(0.05, 0.25, 0.55), vec3(0.35, 0.75, 1.10), w);
    color = vec4(mix(c, c * ocean * 2.2, 0.50), 1.0);
}
