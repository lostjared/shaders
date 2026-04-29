#version 330 core
// Metal glacier — icy blue tint with subtle frost speckle.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec3 glacier = c * vec3(0.78, 0.95, 1.20) + vec3(0.04, 0.08, 0.16);
    float n = hash(floor(tc * iResolution / 2.0));
    float frost = step(0.94, n) * 0.50;
    color = vec4(glacier + vec3(0.8, 0.95, 1.0) * frost, 1.0);
}
