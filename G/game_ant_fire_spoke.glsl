#version 330 core
// Fire spoke — slow radial warm glow from screen center.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float a = atan(p.y, p.x);
    float r = length(p);
    float spokes = 0.5 + 0.5 * sin(a * 8.0 + time_f * 0.4);
    float glow = smoothstep(0.7, 0.0, r) * spokes;
    vec3 fire = vec3(1.0, 0.55, 0.20) * glow * 0.55;
    color = vec4(c + fire, 1.0);
}
