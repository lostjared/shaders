#version 330 core
// Ghost afterimage: fake echo trail by sampling several time-shifted offsets.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 acc = vec3(0.0);
    float total = 0.0;
    for (int i = 0; i < 5; ++i) {
        float t = float(i) / 4.0;
        vec2 off = vec2(sin(time_f + t * 3.0), cos(time_f * 0.8 + t * 3.0)) * 0.012 * t;
        vec3 s = texture(samp, tc + off).rgb;
        float w = 1.0 - t * 0.85;
        acc += s * w * (1.0 - 0.2 * t * vec3(0.0, 0.6, 1.2));
        total += w;
    }
    vec3 c = acc / total;
    color = vec4(c * vec3(0.9, 1.0, 1.1), 1.0);
}
