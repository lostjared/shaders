#version 330 core
// Metal orbital — subtle ring highlight around screen center, slow rotation.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float r = length(p);
    float a = atan(p.y, p.x) + time_f * 0.4;
    float ring = smoothstep(0.05, 0.0, abs(r - 0.32));
    float arc = smoothstep(0.0, 0.5, sin(a * 2.0)) * ring;
    color = vec4(c + vec3(0.85, 0.95, 1.15) * arc * 0.65, 1.0);
}
