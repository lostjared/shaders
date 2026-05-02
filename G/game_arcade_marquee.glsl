#version 330 core
// Arcade marquee: scrolling rainbow light bars on top and bottom edges.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec3 hue(float h) {
    return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float bar = 0.06;
    float topD = smoothstep(bar, 0.0, tc.y);
    float botD = smoothstep(1.0 - bar, 1.0, tc.y);
    float mask = max(topD, botD);
    float bulb = step(0.5, fract(tc.x * 28.0 + time_f * 0.6));
    vec3 marquee = hue(tc.x * 0.7 + time_f * 0.25) * (0.6 + 0.4 * bulb);
    c = mix(c, marquee, mask * 0.85);
    color = vec4(c, 1.0);
}
