#version 330 core
// Bullet-time: desaturate + cool blue grade + soft radial blur from center.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 dir = tc - 0.5;
    vec3 acc = vec3(0.0);
    float total = 0.0;
    for (int i = 0; i < 8; ++i) {
        float t = float(i) / 8.0;
        float k = 1.0 - t * 0.04;
        vec3 s = texture(samp, 0.5 + dir * k).rgb;
        float w = 1.0 - t;
        acc += s * w;
        total += w;
    }
    vec3 c = acc / total;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 cool = mix(vec3(lum), c, 0.35) * vec3(0.85, 0.95, 1.15);
    color = vec4(cool, 1.0);
}
