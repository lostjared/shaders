#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 center = vec2(0.5) + vec2(sin(time_f * 0.47), sin(time_f * 0.71)) * 0.1;
    vec2 p = (tc - center) * ar;
    p.x *= 0.62 + 0.22 * sin(time_f * 0.8);
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float tide = sin(p.x * 36.0 + time_f * 7.0) + cos(p.y * 43.0 - time_f * 9.0);
    float surge = sin(r * 57.0 - time_f * 12.0 + tide * 1.8);
    a += 1.35 / r + time_f * 0.85 + tide * 0.16;
    r += surge * 0.055;
    vec2 q = vec2(cos(a), sin(a)) * r;
    q.x /= 0.62 + 0.22 * sin(time_f * 0.8);
    vec2 uv = fract(q / ar + center);
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, fract(uv + vec2(tide, surge) * 0.025));
    color = vec4(mix(c0.rgb, c1.gbr, 0.34) * (0.78 + abs(surge) * 0.35), c0.a);
}
