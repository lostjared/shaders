#version 330 core
// Simulated CRT phosphor afterglow using mild blur and additive ghost.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;
    vec3 ghost = (texture(samp, tc + vec2(px.x, 0.0)).rgb +
                  texture(samp, tc - vec2(px.x, 0.0)).rgb +
                  texture(samp, tc + vec2(0.0, px.y)).rgb +
                  texture(samp, tc - vec2(0.0, px.y)).rgb) * 0.25;
    vec3 outc = c + max(ghost - 0.55, 0.0) * 0.6;
    float scan = 0.92 + 0.08 * sin(gl_FragCoord.y * 1.2);
    color = vec4(outc * scan, 1.0);
}
