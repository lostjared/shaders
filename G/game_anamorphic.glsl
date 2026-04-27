#version 330 core
// Lens flare anamorphic streak when bright pixels are present.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;
    vec3 streak = vec3(0.0);
    float total = 0.0;
    for (int i = -8; i <= 8; ++i) {
        vec3 s = texture(samp, tc + vec2(float(i) * px.x * 3.0, 0.0)).rgb;
        float bright = max(0.0, max(s.r, max(s.g, s.b)) - 0.75);
        float w = exp(-float(i*i) * 0.05);
        streak += s * bright * w;
        total += w;
    }
    streak /= max(total, 0.001);
    streak *= vec3(0.5, 0.7, 1.0);
    color = vec4(c + streak * 0.7, 1.0);
}
