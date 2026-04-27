#version 330 core
// Handheld-style LCD pixel grid. Adds dot-matrix character to retro/pixel games.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 cell = fract(gl_FragCoord.xy / 2.0);
    float gx = smoothstep(0.0, 0.15, cell.x) * (1.0 - smoothstep(0.85, 1.0, cell.x));
    float gy = smoothstep(0.0, 0.15, cell.y) * (1.0 - smoothstep(0.85, 1.0, cell.y));
    float grid = mix(0.78, 1.0, gx * gy);
    color = vec4(c * grid, 1.0);
}
