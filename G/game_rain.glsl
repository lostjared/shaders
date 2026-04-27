#version 330 core
// Slow, gentle rain streaks falling down. Atmospheric, doesn't hide gameplay.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float h21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 uv = tc * vec2(iResolution.x / iResolution.y, 1.0) * vec2(80.0, 8.0);
    uv.y += time_f * 4.0;
    vec2 cell = floor(uv);
    vec2 f = fract(uv);
    float r = h21(cell);
    float streak = smoothstep(0.0, 0.7, f.y) * (1.0 - smoothstep(0.7, 1.0, f.y));
    streak *= step(0.985, r) * smoothstep(0.5, 0.45, abs(f.x - 0.5));
    c += streak * 0.35;
    color = vec4(c, 1.0);
}
