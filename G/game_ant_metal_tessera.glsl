#version 330 core
// Metal tessera — gentle mosaic tile borders.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * iResolution / 32.0;
    vec2 g = abs(fract(p) - 0.5);
    float edge = smoothstep(0.40, 0.50, max(g.x, g.y));
    color = vec4(mix(c, c * 0.55, edge * 0.85), 1.0);
}
