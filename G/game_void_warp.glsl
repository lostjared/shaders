#version 330 core
// Black-hole gravitational lens warp at the screen center.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 v = tc - 0.5;
    float r = length(v);
    float pull = 0.06 / (r * r + 0.04);
    vec2 dir = normalize(v + 1e-5);
    vec2 uv = tc - dir * pull * 0.02;
    vec3 c = texture(samp, uv).rgb;
    float core = smoothstep(0.10, 0.0, r);
    c = mix(c, vec3(0.0), core);
    float ringR = 0.18 + 0.01 * sin(time_f * 1.5);
    float ring = exp(-pow((r - ringR) * 30.0, 2.0));
    c += vec3(0.4, 0.2, 0.7) * ring;
    color = vec4(c, 1.0);
}
