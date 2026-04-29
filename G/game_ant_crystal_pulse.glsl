#version 330 core
// Crystal pulse — gentle facet brightness pulse on highlights.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float pulse = 0.5 + 0.5 * sin(time_f * 1.4);
    float facet = smoothstep(0.40, 0.95, lum) * pulse;
    vec3 crystal = c + vec3(0.45, 0.70, 1.10) * facet * 0.65;
    crystal *= 1.0 + pulse * 0.10;
    color = vec4(crystal, 1.0);
}
