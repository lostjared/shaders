#version 330
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec4 base = texture(samp, tc);
    float sparkle = abs(sin(time_f * 10.0 + tc.x * 100.0) * cos(time_f * 15.0 + tc.y * 100.0));
    vec3 magicalColor = vec3(sin(time_f * 2.0) * 0.5 + 0.5, cos(time_f * 3.0) * 0.5 + 0.5, sin(time_f * 4.0) * 0.5 + 0.5);
    vec3 glow = magicalColor * sparkle;

    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float r = length(p);
    float ang = atan(p.y, p.x) + time_f * 0.5 + r * 8.0;
    vec2 s = vec2(cos(ang), sin(ang)) * r;
    s.x /= (iResolution.x / iResolution.y);
    s += 0.5;

    float N = 18.0;
    vec2 q = s * N;
    vec2 g = abs(fract(q) - 0.5);
    vec2 w = fwidth(q);
    float lx = 1.0 - smoothstep(0.0, w.x * 1.5, g.x);
    float ly = 1.0 - smoothstep(0.0, w.y * 1.5, g.y);
    float grid = max(lx, ly);

    vec3 spiralColor = 0.5 + 0.5 * cos(vec3(0.0, 2.0, 4.0) + ang * 4.0 + time_f * 2.0);
    vec3 gridRGB = spiralColor * grid * 0.65;

    vec3 rgb = clamp(base.rgb + glow + gridRGB, 0.0, 1.0);
    color = vec4(rgb, base.a);
}
