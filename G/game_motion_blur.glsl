#version 330 core
// Very soft motion-blur fake using mild horizontal blur (preserves picture).
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 acc = vec3(0.0);
    float total = 0.0;
    for (int i = -3; i <= 3; ++i) {
        float w = exp(-float(i*i) * 0.3);
        acc += texture(samp, tc + vec2(float(i) * px.x * 1.2, 0.0)).rgb * w;
        total += w;
    }
    color = vec4(acc / total, 1.0);
}
