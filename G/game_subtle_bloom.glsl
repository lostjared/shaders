#version 330 core
// Cheap bloom that lifts only bright pixels. Adds glow to lights/HUD.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;
    vec3 acc = vec3(0.0);
    float total = 0.0;
    for (int x = -2; x <= 2; ++x) {
        for (int y = -2; y <= 2; ++y) {
            vec2 o = vec2(float(x), float(y)) * px * 2.0;
            vec3 s = texture(samp, tc + o).rgb;
            float bright = max(0.0, max(s.r, max(s.g, s.b)) - 0.65);
            float w = exp(-float(x*x + y*y) * 0.3);
            acc += s * bright * w;
            total += w;
        }
    }
    vec3 bloom = acc / max(total, 0.001);
    color = vec4(c + bloom * 0.6, 1.0);
}
