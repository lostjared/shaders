#version 330 core
// Metal weave — interlocking diagonal weave pattern overlay.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * iResolution / 18.0;
    float w1 = sin((p.x + p.y) * 3.14159);
    float w2 = sin((p.x - p.y) * 3.14159);
    float weave = max(smoothstep(0.6, 1.0, w1), smoothstep(0.6, 1.0, w2)) * 0.40;
    color = vec4(c + vec3(0.95, 0.97, 1.10) * weave, 1.0);
}
