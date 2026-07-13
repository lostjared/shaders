#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec2 vortexUV(vec2 tc0, float turn, float radialShift) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc0 - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float wave = sin(r * 46.0 - time_f * 10.0 + a * 5.0);
    a += time_f * 1.1 + turn / r + wave * 0.28;
    r += radialShift + wave * 0.04;
    return fract(vec2(cos(a), sin(a)) * r / ar + 0.5);
}

void main(void) {
    vec2 ur = vortexUV(tc, 1.22, 0.012);
    vec2 ug = vortexUV(tc, 1.05, 0.0);
    vec2 ub = vortexUV(tc, 0.88, -0.012);
    vec3 rgb = vec3(texture(samp, ur).r,
                    texture(samp, ug).g,
                    texture(samp, ub).b);
    float r = length(tc - 0.5);
    rgb *= 0.85 + 0.35 * sin(r * 70.0 - time_f * 9.0);
    color = vec4(rgb, texture(samp, ug).a);
}
