#version 330 core
// Bullet time focus: sharp center with radial peripheral blur.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 p = tc - 0.5;
    vec2 dir = normalize(p + 1e-5);
    float amount = smoothstep(0.05, 0.36, dot(p, p));
    vec3 acc = vec3(0.0);
    float total = 0.0;
    for (int i = -3; i <= 3; ++i) {
        float f = float(i);
        float w = exp(-f * f * 0.35);
        acc += texture(samp, clamp(tc + dir * f * 0.01 * amount, 0.0, 1.0)).rgb * w;
        total += w;
    }
    vec3 c = acc / total;
    c = mix(c, vec3(dot(c, vec3(0.299, 0.587, 0.114))), amount * 0.25);
    color = vec4(c, 1.0);
}
