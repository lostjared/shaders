#version 330 core
// Metal cascade — diagonal sweep of bright bands cascading slowly.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float s = (tc.x + tc.y) * 6.0 - time_f * 0.6;
    float bands = 0.5 + 0.5 * sin(s);
    float sheen = smoothstep(0.6, 1.0, bands) * 0.45;
    color = vec4(c + vec3(0.95, 0.95, 1.0) * sheen, 1.0);
}
