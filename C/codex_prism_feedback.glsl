#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

vec2 mirrorWrap(vec2 p) {
    return abs(fract(p) * 2.0 - 1.0);
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    float t = time_f * 0.55;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= iResolution.x / max(iResolution.y, 1.0);
    p -= mouseP * 0.08;
    float r = length(p);
    float a = atan(p.y, p.x);
    float folds = 6.0;
    a = abs(mod(a + t * 0.25, 6.283185 / folds) - 3.141592 / folds);
    vec2 q = vec2(cos(a), sin(a)) * r;
    q *= rot(sin(t) * 0.8 + r * 4.0);
    q /= 1.0 + 0.25 * sin(r * 18.0 - t * 3.0);
    vec2 uv = mirrorWrap(q + 0.5);
    float split = 0.004 + 0.02 * smoothstep(0.0, 1.0, sin(r * 20.0 - t) * 0.5 + 0.5);
    vec3 c;
    c.r = texture(samp, mirrorWrap(uv + vec2(split, -split))).r;
    c.g = texture(samp, uv).g;
    c.b = texture(samp, mirrorWrap(uv - vec2(split, -split))).b;
    c += vec3(0.08, 0.05, 0.12) * smoothstep(1.35, 0.0, length(p - mouseP));
    vec3 prism = 0.55 + 0.45 * cos(vec3(0.0, 2.1, 4.2) + a * 5.0 + r * 16.0 - t * 2.0);
    c = mix(c, c * prism + prism * 0.18, 0.55);
    color = vec4(c, 1.0);
}
