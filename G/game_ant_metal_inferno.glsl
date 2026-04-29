#version 330 core
// Metal inferno — orange/red gradient lift bottom to top, gentle flicker.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float fl = 0.85 + 0.15 * sin(time_f * 6.0);
    float bot = smoothstep(0.65, 0.0, tc.y) * fl;
    vec3 inferno = vec3(1.0, 0.35, 0.10);
    color = vec4(c + inferno * bot * 0.65, 1.0);
}
