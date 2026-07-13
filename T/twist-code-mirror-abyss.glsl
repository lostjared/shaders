#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec2 mirrorTile(vec2 uv) {
    return 1.0 - abs(fract(uv * 0.5) * 2.0 - 1.0);
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float lattice = sin(a * 16.0 + r * 42.0 - time_f * 8.0);
    a += 1.35 / r + time_f * 0.85 + lattice * 0.2;
    float rr = fract(-log(r) * 0.45 + time_f * 0.37) * (0.45 + r);
    vec2 q = vec2(cos(a), sin(a)) * rr / ar + 0.5;
    vec2 uv = mirrorTile(q * (3.0 + 0.7 * sin(time_f * 0.6)));
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, mirrorTile(uv.yx * 1.7 + lattice * 0.08));
    float mirrorPulse = 0.5 + 0.5 * cos(a * 8.0 - time_f * 6.0);
    color = vec4(mix(c0.rgb, c1.bgr, 0.2 + mirrorPulse * 0.45), c0.a);
}
