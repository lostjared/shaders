#version 330 core
// Speed boost: directional streaks and bright center tunnel.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 p = tc - 0.5;
    vec2 dir = normalize(p + 1e-5);
    vec3 acc = vec3(0.0);
    float total = 0.0;
    for (int i = 0; i < 8; ++i) {
        float f = float(i);
        float w = exp(-f * 0.32);
        acc += texture(samp, clamp(tc - dir * f * 0.012, 0.0, 1.0)).rgb * w;
        total += w;
    }
    float streak = pow(1.0 - abs(sin(atan(p.y, p.x) * 18.0 + time_f * 8.0)), 9.0);
    vec3 c = acc / total + vec3(0.25, 0.55, 1.0) * streak * length(p);
    color = vec4(c, 1.0);
}
