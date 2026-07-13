#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec2 whirl(vec2 uv, vec2 center, float direction) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (uv - center) * ar;
    float r = length(p) + 0.025;
    float a = atan(p.y, p.x);
    a += direction * (1.0 / r + time_f * 1.25);
    r += sin(r * 48.0 - time_f * 9.0 + direction * a * 6.0) * 0.045;
    return vec2(cos(a), sin(a)) * r / ar + center;
}

void main(void) {
    vec2 orbit = vec2(cos(time_f * 0.7), sin(time_f * 0.7)) * 0.17;
    vec2 u0 = whirl(tc, vec2(0.5) + orbit, 1.0);
    vec2 u1 = whirl(tc, vec2(0.5) - orbit, -1.0);
    vec2 uv = fract(mix(u0, u1, 0.5 + 0.5 * sin((tc.x + tc.y) * 35.0 - time_f * 6.0)));
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, fract(mix(u1, u0, 0.36)));
    float braid = 0.5 + 0.5 * sin((tc.x - tc.y) * 50.0 + time_f * 8.0);
    color = vec4(mix(c0.rgb, c1.bgr, braid * 0.42), c0.a);
}
