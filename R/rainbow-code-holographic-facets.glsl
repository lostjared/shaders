#version 330 core
// rainbow-code-holographic-facets
// Holographic crystalline facets with stable Voronoi edges and anisotropic glints.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

const float TAU = 6.28318530718;
float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
vec2 hash22(vec2 p) {
    float n = hash21(p);
    return fract(vec2(n, n * 34.53));
}
vec3 spectral(float x) {
    return .5 + .5 * cos(TAU * (x + vec3(.0, .33, .67)));
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 aces(vec3 x) {
    x = max(x, 0.0);
    return clamp((x * (2.51 * x + .03)) / (x * (2.43 * x + .59) + .14), 0.0, 1.0);
}
vec3 voronoi(vec2 p) {
    vec2 g = floor(p), f = fract(p);
    float d1 = 9.0, d2 = 9.0;
    vec2 id = vec2(0);
    for (int y = -1; y <= 1; y++)
        for (int x = -1; x <= 1; x++) {
            vec2 o = vec2(x, y), q = o + hash22(g + o) - f;
            float d = dot(q, q);
            if (d < d1) {
                d2 = d1;
                d1 = d;
                id = g + o;
            } else if (d < d2)
                d2 = d;
        }
    return vec3(sqrt(d1), sqrt(d2) - sqrt(d1), hash21(id));
}
void main() {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - .5) * vec2(aspect, 1.0);
    float t = time_f * .12;
    p += vec2(sin(p.y * 4.0 + t * 3.0), cos(p.x * 3.0 - t * 2.0)) * (.025 + amp_low * .03);
    vec3 cell = voronoi(p * (8.0 + amp_mid * 3.0) + vec2(t, -t * .7));
    float edge = 1.0 - smoothstep(.018, .065, cell.y);
    float facet = cell.x;
    vec2 dir = normalize(vec2(cos(cell.z * TAU), sin(cell.z * TAU)));
    vec2 uv = mirrorUV(tc + dir * (facet - .28) * (.04 + amp_low * .025));
    float split = .003 + amp_high * .012;
    vec3 src = vec3(texture(samp, mirrorUV(uv + dir * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - dir * split)).b);
    float sweep = pow(max(0.0, cos(dot(p, dir) * 24.0 - time_f * 1.7 + cell.z * TAU)), 22.0);
    vec3 holo = spectral(cell.z * .7 + facet * .4 + dot(p, vec2(.12, .08)) - time_f * .025);
    vec3 result = mix(src, src * holo * 1.25, .32) + holo * edge * (.22 + amp_peak * .55);
    result += holo * sweep * (.25 + amp_high * .65) + vec3(1.0, .92, .82) * edge * sweep * .35;
    result *= .92 + amp_smooth * .18;
    color = vec4(aces(result), texture(samp, uv).a);
}
