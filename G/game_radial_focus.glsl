#version 330 core
// Center-sharp, edges blurred. Cinematic depth-of-field fake.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 1.0 / iResolution;
    vec2 v = tc - 0.5;
    float k = smoothstep(0.05, 0.45, dot(v, v));
    vec3 sum = vec3(0.0);
    float total = 0.0;
    for (int i = -2; i <= 2; ++i) {
        for (int j = -2; j <= 2; ++j) {
            vec2 o = vec2(float(i), float(j)) * px * (1.5 + 4.0 * k);
            float w = exp(-(float(i * i + j * j)) * 0.4);
            sum += texture(samp, tc + o).rgb * w;
            total += w;
        }
    }
    color = vec4(sum / total, 1.0);
}
