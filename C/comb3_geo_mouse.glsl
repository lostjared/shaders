#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

float h1(float n) { return fract(sin(n) * 43758.5453123); }
vec2 h2(float n) { return fract(sin(vec2(n, n + 1.0)) * vec2(43758.5453, 22578.1459)); }

vec2 rotateUV(vec2 uv, float a, vec2 c, float aspect) {
    float s = sin(a), cv = cos(a);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cv, -s, s, cv) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float r = length(p);
    float seg = 6.28318530718 / segments;
    ang = mod(ang, seg);
    ang = abs(ang - seg * 0.5);
    vec2 q = vec2(cos(ang), sin(ang)) * r;
    q.x /= aspect;
    return q + c;
}

vec2 tileMirror(vec2 uv, float tiles, vec2 c) {
    vec2 p = (uv - c) * tiles;
    p = abs(fract(p) * 2.0 - 1.0);
    return p / tiles + c;
}

vec2 swirl(vec2 uv, vec2 c, float aspect, float k) {
    vec2 p = uv - c;
    p.x *= aspect;
    float r = length(p) + 1e-6;
    float a = atan(p.y, p.x) + k * r;
    vec2 q = vec2(cos(a), sin(a)) * r;
    q.x /= aspect;
    return q + c;
}

vec2 fractalZoom(vec2 uv, float zoom, float t, vec2 c, float aspect) {
    vec2 p = uv;
    for (int i = 0; i < 5; i++) {
        p = abs((p - c) * zoom) - 0.5 + c;
        p = rotateUV(p, t * 0.1, c, aspect);
    }
    return p;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 uv = tc;

    float t = time_f;
    float modef = mod(floor(t * 0.1666667), 4.0);
    int mode = int(modef);
    float seed = floor(t * 0.1666667);
    float seg = 4.0 + floor(h1(seed) * 8.0);
    float tiles = 2.0 + floor(h1(seed + 3.1) * 6.0);
    float k = (h1(seed + 7.7) * 2.0 - 1.0) * (0.6 + 0.6 * sin(t * 0.37));
    float zoom = 1.3 + 0.6 * sin(t * 0.5 + h1(seed + 1.7) * 6.2831853);

    vec2 duv = uv;
    if (mode == 0)
        duv = reflectUV(uv, seg, m, aspect);
    if (mode == 1)
        duv = tileMirror(rotateUV(uv, 0.4 * sin(t * 0.6), m, aspect), tiles, m);
    if (mode == 2)
        duv = swirl(uv, m, aspect, k * 6.0);
    if (mode == 3)
        duv = fractalZoom(uv, zoom, t, m, aspect);

    vec2 d = uv - m;
    float dist = length(d);
    float r = 0.45;
    float w = 1.0 - smoothstep(0.0, r, dist);
    vec2 warp = normalize(d + 1e-5) * sin(dist * (18.0 + seg) - t * (2.0 + h1(seed) * 3.0)) * 0.12 * w;
    duv += warp;

    duv = vec2(pingPong(duv.x + 0.05 * sin(t), 1.0), pingPong(duv.y + 0.05 * cos(t), 1.0));

    vec4 base = texture(samp, uv);
    vec4 fx = texture(samp, duv);
    float blend = 0.45 + 0.25 * sin(t * 0.8);
    vec4 mixedCol = mix(base, fx, blend);

    mixedCol.rgb *= 0.5 + 0.5 * sin(duv.xyx * (2.0 + seg * 0.1) + t);

    vec4 c1 = sin(mixedCol * pingPong(t, 10.0));
    vec4 t0 = texture(samp, tc);
    vec4 c2 = sin(c1 * t0 * 0.8 * pingPong(t, 15.0));

    color = c2;
    color.a = 1.0;
}
