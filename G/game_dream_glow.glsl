#version 330 core
// Soft dreamy glow - gaussian-ish blur added on top of the original.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;
    vec3 g = vec3(0.0);
    float total = 0.0;
    for (int i = -3; i <= 3; ++i) {
        for (int j = -3; j <= 3; ++j) {
            float w = exp(-(float(i * i + j * j)) * 0.18);
            g += texture(samp, tc + vec2(float(i), float(j)) * px * 1.5).rgb * w;
            total += w;
        }
    }
    g /= total;
    vec3 outc = c + g * 0.35;
    outc = (outc - 0.5) * 1.05 + 0.5;
    color = vec4(clamp(outc, 0.0, 1.0), 1.0);
}
