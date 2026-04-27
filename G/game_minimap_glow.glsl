#version 330 core
// Stylized minimap-style overlay: blue grade, grid lines, soft radial glow.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 blue = mix(vec3(0.02, 0.08, 0.18), vec3(0.45, 0.85, 1.2), lum);
    vec2 g = abs(fract(tc * vec2(20.0, 12.0)) - 0.5);
    float grid = smoothstep(0.48, 0.5, max(g.x, g.y));
    float ping = 0.5 + 0.5 * sin(time_f * 2.0 - length(tc - 0.5) * 18.0);
    blue += vec3(0.1, 0.3, 0.5) * grid;
    blue += vec3(0.1, 0.4, 0.6) * pow(ping, 4.0) * 0.4;
    color = vec4(blue, 1.0);
}
